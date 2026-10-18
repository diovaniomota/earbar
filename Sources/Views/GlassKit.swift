import SwiftUI

// The building blocks every page of the menu-bar panel is made of, so the
// sub-pages read exactly like the dashboard: content straight on the panel's
// glass, section titles in small bold secondary type, rows 34pt high with the
// control at the trailing edge, hairlines between sections, pill-shaped
// segmented pickers — and nothing boxed in a card.

/// A sub-page: back chevron and title on top, then the content. The page is
/// as tall as its content up to `DetailLayout.height`, beyond which it
/// scrolls — short pages like Find earbuds don't trail an empty half-panel,
/// and the panel re-anchors under the icon whenever its height changes.
struct DetailPage<Content: View>: View {
    let title: LocalizedStringKey
    let onBack: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(GlassRowButtonStyle())
                .accessibilityLabel(Text("Back"))
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)
            GlassDivider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: DetailLayout.height)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(width: DetailLayout.width)
    }
}

/// A titled run of rows. Put a `GlassDivider` between sections.
struct GlassSection<Content: View>: View {
    var title: LocalizedStringKey?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
            }
            content()
        }
    }
}

struct GlassDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 4).padding(.vertical, 7)
    }
}

/// A row: title (and optional subtitle) on the left, any control on the right.
struct GlassRow<Trailing: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                if let subtitle {
                    Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 34)
    }
}

/// A row whose control is a switch.
struct GlassToggleRow: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        GlassRow(title: title, subtitle: subtitle) {
            Toggle("", isOn: Binding(get: { isOn }, set: onChange))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

/// A tappable row with an optional coloured glyph disc, the way the dashboard
/// lists its pages.
struct GlassButtonRow: View {
    let title: LocalizedStringKey
    var icon: String?
    var color: Color = .gray
    var role: ButtonRole?
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 10) {
                if let icon { GlassGlyph(symbol: icon, color: color) }
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(minHeight: 34)
        }
        .buttonStyle(GlassRowButtonStyle())
    }
}

/// The coloured disc the system's Bluetooth panel puts before a device.
struct GlassGlyph: View {
    let symbol: String
    let color: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(color))
    }
}

/// A pill-shaped segmented picker for a handful of text options — the same
/// shape as the listening-mode control, at row height.
struct GlassSegmented<Option: Hashable>: View {
    let options: [(value: Option, label: LocalizedStringKey)]
    let selection: Option
    var tint: Color = .accentColor
    let onSelect: (Option) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                let selected = option.value == selection
                Button { onSelect(option.value) } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Capsule().fill(selected ? tint : Color.clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.primary.opacity(0.07)))
    }
}

/// Explanatory text under a section, in the panel's small secondary type.
struct GlassFootnote: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
    }
}

/// A full-width call-to-action in the panel: a capsule in the device tint,
/// or a quiet grey one for secondary actions.
struct GlassActionButton: View {
    let title: LocalizedStringKey
    var icon: String?
    var tint: Color = .accentColor
    var prominent = true
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(Capsule().fill(prominent ? tint : Color.primary.opacity(0.08)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}
