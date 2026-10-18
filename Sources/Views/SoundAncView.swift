import SwiftUI

/// Detailed Sound & ANC settings, pushed in from the dashboard and drawn in
/// the same language: titled sections of rows straight on the panel's glass,
/// hairlines between them. Gated controls only appear for models that
/// support them.
struct SoundAncView: View {
    @Bindable var bluetooth: BluetoothManager
    let onBack: () -> Void

    private var status: BudsStatus { bluetooth.status }
    private var tint: Color { .accentColor }

    var body: some View {
        DetailPage(title: "Sound & ANC", onBack: onBack) {
            noiseSection
            GlassDivider()
            ambientSection
            if bluetooth.connectedModel?.supportsDetectConversations == true {
                GlassDivider()
                conversationsSection
            }
            GlassDivider()
            callsSection
        }
    }

    // MARK: - Sections

    private var noiseSection: some View {
        GlassSection(title: "Noise cancelling") {
            // Strength only applies while ANC is the active mode; adaptive
            // chooses its own. Dimmed to match the panel and the dashboard.
            let ancActive = status.noiseControlMode == .anc
            if bluetooth.connectedModel?.supportsAncStrength == true {
                GlassRow(title: "ANC strength") {
                    AncStrengthStepper(
                        level: status.ancLevel,
                        count: bluetooth.connectedModel?.ancLevelCount ?? 2,
                        tint: tint
                    ) { bluetooth.setAncLevel($0) }
                    .frame(width: 200)
                }
                .disabled(!ancActive)
                .opacity(ancActive ? 1 : 0.45)
            }
            GlassToggleRow(title: "Noise control with one earbud",
                           isOn: status.ncWithOneEarbud) { bluetooth.setNoiseControlWithOneEarbud($0) }
        }
    }

    private var ambientSection: some View {
        GlassSection(title: "Ambient sound") {
            GlassRow(title: "Ambient volume") {
                volumeSlider(value: status.ambientSoundVolume) { bluetooth.setAmbientVolume($0) }
            }
            GlassToggleRow(title: "Customize ambient sound",
                           isOn: status.ambientCustomEnabled) {
                bluetooth.setCustomAmbient(enabled: $0, left: status.ambientCustomLeft,
                                           right: status.ambientCustomRight, tone: status.ambientTone)
            }
            if status.ambientCustomEnabled {
                GlassRow(title: "Left") {
                    volumeSlider(value: status.ambientCustomLeft) {
                        bluetooth.setCustomAmbient(enabled: true, left: $0,
                                                   right: status.ambientCustomRight, tone: status.ambientTone)
                    }
                }
                GlassRow(title: "Right") {
                    volumeSlider(value: status.ambientCustomRight) {
                        bluetooth.setCustomAmbient(enabled: true, left: status.ambientCustomLeft,
                                                   right: $0, tone: status.ambientTone)
                    }
                }
                GlassRow(title: "Tone") {
                    GlassSegmented(
                        options: [(value: 0, label: "Low"), (value: 1, label: "Mid"), (value: 2, label: "High")],
                        selection: status.ambientTone,
                        tint: tint
                    ) {
                        bluetooth.setCustomAmbient(enabled: true, left: status.ambientCustomLeft,
                                                   right: status.ambientCustomRight, tone: $0)
                    }
                    .frame(width: 200)
                }
            }
        }
    }

    private var conversationsSection: some View {
        GlassSection(title: "Conversations") {
            GlassToggleRow(title: "Detect conversations",
                           isOn: status.detectConversations) { bluetooth.setDetectConversations($0) }
            if status.detectConversations {
                GlassRow(title: "Duration") {
                    GlassSegmented(
                        options: [(value: 0, label: "5s"), (value: 1, label: "10s"), (value: 2, label: "15s")],
                        selection: status.detectConversationsDuration,
                        tint: tint
                    ) { bluetooth.setDetectConversationsDuration($0) }
                    .frame(width: 200)
                }
            }
        }
    }

    private var callsSection: some View {
        GlassSection(title: "Calls") {
            GlassToggleRow(title: "Sidetone (own voice)",
                           isOn: status.sidetone) { bluetooth.setSidetone($0) }
            GlassToggleRow(title: "Ambient sound during calls",
                           isOn: status.ambientDuringCalls) { bluetooth.setAmbientDuringCalls($0) }
        }
    }

    // MARK: - Building blocks

    /// A 3-stop (0...2) volume slider.
    private func volumeSlider(value: Int, action: @escaping (Int) -> Void) -> some View {
        Slider(
            value: Binding(get: { Double(value) }, set: { action(Int($0.rounded())) }),
            in: 0...2, step: 1
        )
        .frame(width: 180)
    }
}
