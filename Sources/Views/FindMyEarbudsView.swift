import SwiftUI

/// "Find My Earbuds" detail page: rings both earbuds and lets you silence one
/// side while searching for the other. The speaker glyph and its line sit
/// straight on the glass above the full-width ring capsule; the Mute section
/// only appears while the tone plays.
struct FindMyEarbudsView: View {
    @Bindable var bluetooth: BluetoothManager
    let onBack: () -> Void

    @State private var isRinging = false
    @State private var muteLeft = false
    @State private var muteRight = false

    private var tint: Color { .accentColor }

    var body: some View {
        DetailPage(title: "Find earbuds", onBack: { stopRinging(); onBack() }) {
            ringControl
            if isRinging {
                GlassDivider()
                muteSection
            }
        }
        .onDisappear { stopRinging() }
    }

    private var ringControl: some View {
        VStack(spacing: 14) {
            Image(systemName: isRinging ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.system(size: 56))
                .foregroundStyle(isRinging ? tint : .secondary)
                .symbolEffect(.variableColor, isActive: isRinging)
                .padding(.top, 20)

            Text(isRinging
                 ? "Playing a sound on your earbuds."
                 : "Ring your earbuds to locate them.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            GlassActionButton(
                title: isRinging ? "Stop" : "Play sound",
                tint: tint, prominent: !isRinging,
                action: toggleRinging
            )
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }

    private var muteSection: some View {
        GlassSection(title: "Mute") {
            GlassToggleRow(title: "Left", isOn: muteLeft) {
                muteLeft = $0
                bluetooth.setMuteEarbud(left: muteLeft, right: muteRight)
            }
            GlassToggleRow(title: "Right", isOn: muteRight) {
                muteRight = $0
                bluetooth.setMuteEarbud(left: muteLeft, right: muteRight)
            }
        }
    }

    private func toggleRinging() {
        if isRinging {
            isRinging = false
            bluetooth.findMyBuds(start: false)
        } else {
            muteLeft = false
            muteRight = false
            isRinging = true
            bluetooth.findMyBuds(start: true)
        }
    }

    /// Used by Back / onDisappear to ensure the tone stops when leaving.
    private func stopRinging() {
        guard isRinging else { return }
        isRinging = false
        bluetooth.findMyBuds(start: false)
    }
}
