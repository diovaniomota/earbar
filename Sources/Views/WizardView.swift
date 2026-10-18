import SwiftUI

/// The connect flow shown in the panel while no buds are connected: welcome,
/// model selection, scanning for devices, then the connection result. It is
/// drawn with the same kit as the dashboard's sub-pages — rows straight on
/// the glass, hairlines between blocks, capsule actions — so the panel reads
/// the same before and after a device is connected. It has no parent page, so
/// it keeps the panel's fixed size itself instead of going through
/// `DetailPage`.
struct WizardView: View {
    @Bindable var bluetooth: BluetoothManager
    let onComplete: () -> Void

    @State private var step: WizardStep = .welcome
    @State private var selectedModel: BudsModel = .buds4Pro
    @State private var selectedDevice: BluetoothManager.DiscoveredDevice?

    enum WizardStep: Int, CaseIterable {
        case welcome
        case selectModel
        case scanning
        case connecting
    }

    /// Nothing is connected yet, so the candidate model's colour stands in
    /// for the device tint the dashboard uses.
    private var tint: Color { .accentColor }

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator

            GlassDivider()

            Group {
                switch step {
                case .welcome:
                    welcomeStep
                case .selectModel:
                    selectModelStep
                case .scanning:
                    scanningStep
                case .connecting:
                    connectingStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(width: DetailLayout.width, height: DetailLayout.height)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 10) {
            ForEach(WizardStep.allCases, id: \.rawValue) { s in
                Circle()
                    .fill(s.rawValue <= step.rawValue ? tint : Color.primary.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            Spacer()

            heroGlyph("airpodspro", color: tint)

            Text("Welcome to Earbar")
                .font(.system(size: 15, weight: .semibold))

            Text("Connect your Samsung Galaxy Buds\nfor battery info, ANC controls, and more.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            GlassActionButton(title: "Get Started", tint: tint) { step = .selectModel }
        }
    }

    // MARK: - Select Model

    /// The flagship/newest models shown as rows; everything else lives in the
    /// menu below (newest first).
    private var featuredModels: [BudsModel] {
        [.buds4Pro, .buds4, .buds3Pro, .buds3]
    }

    private var olderModels: [BudsModel] {
        BudsModel.allCases.reversed().filter { !featuredModels.contains($0) }
    }

    private var selectModelStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Select Your Model")
                    .font(.system(size: 15, weight: .semibold))
                Text("Pick your Galaxy Buds")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)

            GlassDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(featuredModels) { model in
                        modelRow(model)
                    }
                    otherModelsRow
                }
            }

            Spacer(minLength: 0)

            GlassFootnote(text: "Selected: \(selectedModel.rawValue)")
            GlassActionButton(title: "Next", tint: tint) {
                step = .scanning
                bluetooth.startScanning()
            }
        }
    }

    /// A selectable row with the model's coloured glyph, its year and
    /// capability badge, and a tick on the current choice.
    private func modelRow(_ model: BudsModel) -> some View {
        let isSelected = selectedModel == model
        return Button(action: { selectedModel = model }) {
            HStack(spacing: 10) {
                GlassGlyph(symbol: model.iconName, color: model.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: model.rawValue)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                    HStack(spacing: 4) {
                        Text(verbatim: model.releaseYear)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        if let badge = model.capabilityBadge {
                            Text(verbatim: badge)
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(model.tint.opacity(0.18)))
                                .foregroundStyle(model.tint)
                        }
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
        }
        .buttonStyle(GlassRowButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Native menu for the remaining models at the row's trailing edge —
    /// keeps the picker compact instead of a long scroll. A Menu (not Picker)
    /// lets us show a placeholder when the current selection is a featured
    /// model.
    private var otherModelsRow: some View {
        GlassRow(title: "Other models") {
            Menu {
                ForEach(olderModels) { model in
                    Button(model.rawValue) { selectedModel = model }
                }
            } label: {
                // Separate branches so the placeholder localizes (a String
                // in a ternary uses Text's non-localizing initializer) while
                // the model name stays verbatim.
                HStack(spacing: 4) {
                    if olderModels.contains(selectedModel) {
                        Text(verbatim: selectedModel.rawValue)
                    } else {
                        Text("Choose a model…")
                    }
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 10))
                }
                .font(.system(size: 13))
                .foregroundStyle(olderModels.contains(selectedModel) ? .primary : .secondary)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        }
    }

    // MARK: - Scanning

    private var scanningStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    bluetooth.stopScanning()
                    step = .selectModel
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(GlassRowButtonStyle())
                .accessibilityLabel(Text("Back"))
                Text("Looking for Galaxy Buds...")
                    .font(.system(size: 15, weight: .semibold))
                Spacer(minLength: 0)
                if bluetooth.isScanning {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)

            GlassDivider()

            if let error = bluetooth.connectionError {
                resultRow(icon: "exclamationmark.triangle.fill", color: .orange, text: Text(error))
            }

            if bluetooth.discoveredDevices.isEmpty && !bluetooth.isScanning
                && bluetooth.connectionError == nil {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No devices found")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("Make sure your buds are in pairing mode\nor already paired with this Mac.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(bluetooth.discoveredDevices) { device in
                        deviceRow(device)
                    }
                }
            }
            .onChange(of: bluetooth.discoveredDevices.count) { _, _ in
                // Auto-select the model inferred from the first discovered
                // device so the picker reflects the actual connected buds.
                if let first = bluetooth.discoveredDevices.first,
                   let detected = BudsModel.detect(from: first.name) {
                    selectedModel = detected
                }
            }

            Spacer(minLength: 0)

            GlassActionButton(title: "Rescan", tint: tint) {
                bluetooth.startScanning()
            }
        }
    }

    private func deviceRow(_ device: BluetoothManager.DiscoveredDevice) -> some View {
        // Prefer the model inferred from the device's own advertised name; only
        // fall back to the manual picker when the name isn't recognizable.
        let model = BudsModel.detect(from: device.name) ?? selectedModel
        return Button(action: {
            selectedModel = model
            selectedDevice = device
            step = .connecting
            bluetooth.connect(to: device, model: model)
        }) {
            HStack(spacing: 10) {
                GlassGlyph(symbol: model.iconName, color: model.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: device.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                    Text(verbatim: model.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
        }
        .buttonStyle(GlassRowButtonStyle())
    }

    // MARK: - Connecting

    private var connectingStep: some View {
        VStack(spacing: 12) {
            Spacer()

            if bluetooth.isConnected {
                heroGlyph("checkmark", color: .green)

                Text("Connected!")
                    .font(.system(size: 15, weight: .semibold))

                Text("Your \(selectedModel.rawValue) is ready.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                GlassActionButton(title: "Done", tint: tint, action: onComplete)
            } else if let error = bluetooth.connectionError {
                heroGlyph("exclamationmark", color: .red)

                Text("Connection Failed")
                    .font(.system(size: 15, weight: .semibold))

                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                GlassActionButton(title: "Try Again", tint: tint) {
                    step = .scanning
                    bluetooth.startScanning()
                }
            } else {
                ProgressView()
                    .controlSize(.large)

                Text("Connecting to \(selectedDevice?.name ?? "device")...")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Building blocks

    /// The dashboard header's device disc at hero size, for the steps that
    /// centre one symbol above their title.
    private func heroGlyph(_ symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 56, height: 56)
            .background(Circle().fill(color))
    }

    /// Takes a `Text` so the runtime error string from the manager can be
    /// shown without going through the string catalogue.
    private func resultRow(icon: String, color: Color, text: Text) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color)
            text.font(.system(size: 13)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
