import SwiftUI

/// Listen-mode picker drawn like the "Listening Mode" control in the AirPods
/// pane of System Settings: a grey pill track, the selected segment a solid
/// capsule in the accent colour with a white icon, and the labels set
/// underneath the track rather than inside it.
struct ListenModePicker: View {
    let modes: [NoiseControlMode]
    let selection: NoiseControlMode
    var tint: Color = .accentColor
    let onSelect: (NoiseControlMode) -> Void

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 0) {
                ForEach(modes) { mode in
                    segment(mode)
                }
            }
            .padding(4)
            .background(Capsule().fill(Color.primary.opacity(0.07)))
            HStack(spacing: 0) {
                ForEach(modes) { mode in
                    Text(LocalizedStringKey(mode.displayName))
                        .font(.system(size: 11, weight: mode == selection ? .semibold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func segment(_ mode: NoiseControlMode) -> some View {
        let selected = mode == selection
        return Button { onSelect(mode) } label: {
            ZStack {
                if selected {
                    Capsule().fill(tint)
                }
                Image(systemName: mode.iconName)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(selected ? Color.white : Color.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: selected)
        .accessibilityLabel(Text(LocalizedStringKey(mode.displayName)))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

/// The battery line macOS prints under an AirPods name: a glyph per part
/// followed by its percentage. Parts that aren't reporting are left out —
/// the case only reports while the buds sit in it.
struct BatteryGlyphLine: View {
    let status: BudsStatus
    var showsCase = true

    var body: some View {
        HStack(spacing: 10) {
            if status.batteryLeft > 0 {
                part("airpodpro.left", status.batteryLeft, charging: status.isLeftCharging)
            }
            if status.batteryRight > 0 {
                part("airpodpro.right", status.batteryRight, charging: status.isRightCharging)
            }
            if showsCase, status.batteryCase > 0 {
                part("airpodspro.chargingcase.wireless.fill", status.batteryCase, charging: false)
            }
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func part(_ symbol: String, _ level: Int, charging: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            if charging {
                Image(systemName: "bolt.fill").font(.system(size: 8))
            }
            Text(verbatim: "\(level)%").monospacedDigit()
        }
    }
}
