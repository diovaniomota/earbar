import SwiftUI

/// Firmware update page: checks the community archive for a newer build,
/// downloads it, and hands it to `FirmwareUpdater` to flash.
///
/// Flashing is the one irreversible thing this app can do to the hardware, so
/// the page only ever offers a strictly newer build, refuses to start on low
/// battery, and states plainly what must not happen during the transfer.
struct FirmwareUpdateView: View {
    @Bindable var bluetooth: BluetoothManager
    let onBack: () -> Void

    /// Samsung's own updater refuses below half charge, and a bud that dies
    /// mid-flash is the way these get bricked.
    private static let minimumBattery = 50

    private enum Check: Equatable {
        case idle
        case checking
        case upToDate
        case available(FirmwareRelease)
        case failed(String)

        static func == (lhs: Check, rhs: Check) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking), (.upToDate, .upToDate): true
            case let (.available(a), .available(b)): a.buildName == b.buildName
            case let (.failed(a), .failed(b)): a == b
            default: false
            }
        }
    }

    @State private var check: Check = .idle
    @State private var isDownloading = false
    @State private var confirming: FirmwareRelease?

    private var status: BudsStatus { bluetooth.status }
    private var tint: Color { .accentColor }
    private var updater: FirmwareUpdater { bluetooth.firmware }

    private var batteryTooLow: Bool {
        min(status.batteryLeft, status.batteryRight) < Self.minimumBattery
    }

    var body: some View {
        // Leaving the page mid-transfer would hide the progress and the
        // warning, so the back chevron is inert while the updater runs.
        DetailPage(title: "Firmware", onBack: { if !updater.isRunning { onBack() } }) {
            GlassSection(title: "Installed") {
                GlassRow(title: "Current version") {
                    Text(verbatim: status.softwareVersion.isEmpty ? "—" : status.softwareVersion)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            GlassDivider()
            if updater.isRunning || isTerminal {
                transferSection
            } else {
                availableSection
            }
        }
        .confirmationDialog(
            "Install this firmware?",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            Button("Install firmware", role: .destructive) {
                if let release = confirming { install(release) }
                confirming = nil
            }
            Button("Cancel", role: .cancel) { confirming = nil }
        } message: {
            Text("Keep both earbuds in the case with the lid open, keep your Mac nearby, and don't quit the app. Interrupting a firmware update can leave the earbuds unusable.")
        }
    }

    private var isTerminal: Bool {
        updater.phase == .finished || isFailed
    }

    private var isFailed: Bool {
        if case .failed = updater.phase { return true }
        return false
    }

    // MARK: - Available

    private var availableSection: some View {
        GlassSection(title: "Update") {
            switch check {
            case .idle:
                GlassFootnote(text: "Firmware comes from a community archive of Samsung's official builds, not from Samsung directly.")
                checkButton

            case .checking:
                progressRow(label: "Checking for updates…", value: nil)

            case .upToDate:
                resultRow(
                    icon: "checkmark.circle.fill", color: .green,
                    text: Text("Your earbuds are up to date."))
                checkButton

            case .available(let release):
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: release.buildName)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    if !release.releaseDescription.isEmpty {
                        Text(verbatim: release.releaseDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)

                if batteryTooLow {
                    resultRow(
                        icon: "exclamationmark.triangle.fill", color: .orange,
                        text: Text("Charge both earbuds before updating — each needs at least half its battery."))
                }

                // The download has no cancel, so while it runs the button gives
                // way to a progress row rather than sitting there greyed out.
                if isDownloading {
                    progressRow(label: "Downloading…", value: nil)
                } else {
                    GlassActionButton(
                        title: "Install update", tint: tint,
                        enabled: !(batteryTooLow || isDownloading || !bluetooth.isConnected)
                    ) { confirming = release }
                }

            case .failed(let message):
                resultRow(icon: "exclamationmark.triangle.fill", color: .red, text: Text(message))
                checkButton
            }
        }
    }

    private var checkButton: some View {
        GlassActionButton(
            title: "Check for updates", tint: tint,
            enabled: bluetooth.isConnected && !status.softwareVersion.isEmpty
        ) { Task { await runCheck() } }
    }

    // MARK: - Transfer

    private var transferSection: some View {
        GlassSection(title: "Update") {
            switch updater.phase {
            case .preparing:
                progressRow(label: "Preparing…", value: nil)
            case .sending(let fraction):
                progressRow(label: "Sending firmware…", value: fraction)
            case .installing(let percent):
                progressRow(label: "Installing…", value: Double(percent) / 100)
            case .finished:
                resultRow(
                    icon: "checkmark.circle.fill", color: .green,
                    text: Text("Firmware sent. The earbuds are installing it and will reconnect on their own."))
                doneButton
            case .failed(let message):
                resultRow(icon: "exclamationmark.triangle.fill", color: .red, text: Text(message))
                doneButton
            case .idle:
                EmptyView()
            }

            if updater.isRunning {
                GlassFootnote(text: "Don't quit the app or move the earbuds away from your Mac.")
            }
        }
    }

    private var doneButton: some View {
        GlassActionButton(title: "Done", prominent: false) {
            updater.reset()
            check = .idle
        }
    }

    /// A determinate phase gets a bar under its label; an indeterminate one
    /// is a plain row with a spinner at the trailing edge.
    @ViewBuilder
    private func progressRow(label: LocalizedStringKey, value: Double?) -> some View {
        if let value {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.system(size: 13))
                ProgressView(value: value).tint(tint)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        } else {
            GlassRow(title: label) {
                ProgressView().controlSize(.small)
            }
        }
    }

    /// Takes a `Text` so callers can pass either a localized literal or an
    /// already-localized runtime message (an error from the catalog or updater).
    private func resultRow(icon: String, color: Color, text: Text) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            text.font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func runCheck() async {
        guard let model = bluetooth.connectedModel else { return }
        check = .checking
        do {
            let releases = try await FirmwareCatalog().releases(for: model)
            let current = status.softwareVersion
            let newest = releases.first { FirmwareVersion.isNewer($0.buildName, than: current) }
            check = newest.map(Check.available) ?? .upToDate
        } catch {
            check = .failed(error.localizedDescription)
        }
    }

    private func install(_ release: FirmwareRelease) {
        isDownloading = true
        Task {
            defer { isDownloading = false }
            do {
                let data = try await FirmwareCatalog().download(release)
                let binary = try FirmwareBinary(data: data, buildName: release.buildName)
                guard bluetooth.isConnected else {
                    check = .failed(String(localized: "The earbuds disconnected."))
                    return
                }
                updater.start(binary: binary, channelMtu: bluetooth.channelMtu)
            } catch {
                check = .failed(error.localizedDescription)
            }
        }
    }
}
