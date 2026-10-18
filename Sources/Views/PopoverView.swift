import AppKit
import SwiftUI

/// Width of the dashboard and its sub-pages, and the fixed height the
/// scrolling sub-pages take. The dashboard itself is as tall as its content.
enum DetailLayout {
    static let width: CGFloat = 440
    static let height: CGFloat = 560
}

/// Button style for a row drawn straight on the panel's glass: no chrome of
/// its own, just the hover highlight a menu item gets.
struct GlassRowButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : hovering ? 0.07 : 0))
            )
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .onHover { hovering = $0 }
    }
}

/// The backdrop of the menu-bar panel: the same `NSVisualEffectView`
/// material the system's own menu-bar panels (Bluetooth, Sound, Control
/// Center) are drawn on. SwiftUI's `.thickMaterial` renders flatter and
/// greyer and doesn't pick up colour from what's behind the window.
struct PanelMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// Rounded corners and the hairline every system panel has, shared by both
/// panel faces so they match.
struct PanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PanelMaterial())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
    }
}

/// Root of the detail window. Shows the connect wizard until a device is
/// connected, then the detailed dashboard. (The menu-bar popover handles the
/// compact quick view separately.)
struct PopoverView: View {
    @Bindable var bluetooth: BluetoothManager

    var body: some View {
        Group {
            if bluetooth.isConnected {
                DashboardView(bluetooth: bluetooth)
            } else {
                WizardView(bluetooth: bluetooth) {}
            }
        }
        .focusEffectDisabled() // no focus ring on auto-focused default buttons
    }
}
