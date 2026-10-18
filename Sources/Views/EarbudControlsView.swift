import SwiftUI

/// "Earbud controls" detail page: touch-and-hold action per side, the noise-
/// control cycle subset when that action is Noise control, and the touchpad
/// lock — rows straight on the panel's glass like the dashboard. Single/
/// double/triple tap are fixed by the firmware, so they're not shown as
/// reassignable.
struct EarbudControlsView: View {
    @Bindable var bluetooth: BluetoothManager
    let onBack: () -> Void

    private var status: BudsStatus { bluetooth.status }
    private var tint: Color { .accentColor }

    var body: some View {
        DetailPage(title: "Earbud controls", onBack: onBack) {
            holdSection
            GlassDivider()
            lockSection
        }
    }

    private var holdSection: some View {
        GlassSection(title: "Touch and hold") {
            holdRow("Left", action: status.touchHoldLeft) {
                bluetooth.setTouchHoldActions(left: $0, right: status.touchHoldRight)
            }
            if status.touchHoldLeft == .noiseControl {
                cycleRow("Left cycle", cycle: status.noiseCycleLeft) {
                    bluetooth.setNoiseControlCycle(left: $0, right: status.noiseCycleRight)
                }
            }
            holdRow("Right", action: status.touchHoldRight) {
                bluetooth.setTouchHoldActions(left: status.touchHoldLeft, right: $0)
            }
            if status.touchHoldRight == .noiseControl {
                cycleRow("Right cycle", cycle: status.noiseCycleRight) {
                    bluetooth.setNoiseControlCycle(left: status.noiseCycleLeft, right: $0)
                }
            }
        }
    }

    private var lockSection: some View {
        GlassSection(title: "Touchpad") {
            GlassToggleRow(title: "Touchpad lock",
                           isOn: status.touchpadLocked) { bluetooth.setTouchpadLock($0) }
        }
    }

    /// The hold action stays a menu: four choices whose translations
    /// ("Голосовой помощник") are too long for a pill at row width.
    private func holdRow(
        _ title: LocalizedStringKey, action: TouchHoldAction,
        set: @escaping (TouchHoldAction) -> Void
    ) -> some View {
        GlassRow(title: title) {
            Menu {
                ForEach(TouchHoldAction.allCases) { option in
                    Button { set(option) } label: { Text(LocalizedStringKey(option.displayName)) }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(action.displayName))
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        }
    }

    /// The cycle is a pill picker under its row title, the way the dashboard
    /// places the listening-mode picker: three labels like "Ambiente /
    /// Desligado" need the full row width to stay readable.
    private func cycleRow(
        _ title: LocalizedStringKey, cycle: NoiseControlCycle,
        set: @escaping (NoiseControlCycle) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GlassRow(title: title) { EmptyView() }
            GlassSegmented(
                options: NoiseControlCycle.allCases.map {
                    (value: $0, label: LocalizedStringKey($0.displayName))
                },
                selection: cycle,
                tint: tint,
                onSelect: set
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
    }
}
