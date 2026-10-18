#!/usr/bin/env swift
import AppKit

/// Composes the Mac App Store screenshots from the panel previews that
/// `Earbar --preview <dir>` renders. Run manually at release time:
///
///     swift scripts/store-screenshots.swift <previews-dir> <out-dir>
///
/// Each shot is 2560×1600 (the App Store's 16:10 Mac size): a soft diagonal
/// gradient, a one-line caption, and the panel PNG at its natural 2× pixel size
/// with a drop shadow. Nothing is upscaled — the previews are already Retina —
/// so the panels stay as crisp as they are on screen; a panel that would not
/// fit is scaled down instead. Written in Swift because the build Macs have
/// no Python imaging library, and AppKit already knows how to draw text in
/// SF Pro and shadows that look like the system's own.

let args = CommandLine.arguments
guard args.count == 3 else {
    FileHandle.standardError.write("usage: store-screenshots.swift <previews-dir> <out-dir>\n".data(using: .utf8)!)
    exit(2)
}
let previews = URL(fileURLWithPath: args[1])
let outDir = URL(fileURLWithPath: args[2])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let canvas = CGSize(width: 2560, height: 1600)
let margin: CGFloat = 120
let captionSize: CGFloat = 72
let captionGap: CGFloat = 72   // space between caption baseline area and the panel
let panelGap: CGFloat = 96     // horizontal gap between two panels in the pair shot

/// One screenshot: which previews to place (left to right) and the look.
struct Shot {
    let file: String
    let panels: [String]
    let caption: String
    let dark: Bool
}

let shots: [Shot] = [
    Shot(file: "01.png", panels: ["quick-light"], caption: "Your Galaxy Buds, in the menu bar", dark: false),
    Shot(file: "02.png", panels: ["dashboard-light"], caption: "Listening mode, ANC strength, every setting", dark: false),
    Shot(file: "03.png", panels: ["sound-anc-light"], caption: "Ambient sound, conversation detection, calls", dark: false),
    Shot(file: "04.png", panels: ["equalizer-light"], caption: "Presets and a 9-band custom equalizer", dark: false),
    Shot(file: "05.png", panels: ["quick-dark", "dashboard-dark"], caption: "Light and dark, like the system's own panels", dark: true),
]

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// Loads a preview as a bitmap so we can place it by *pixel* size. NSImage's
/// own `size` is in points (the previews are tagged 144 dpi, so half the
/// pixels), which would draw them at a quarter of the area.
func loadPanel(_ name: String) -> NSBitmapImageRep {
    let url = previews.appendingPathComponent("\(name).png")
    guard let data = try? Data(contentsOf: url), let rep = NSBitmapImageRep(data: data) else {
        FileHandle.standardError.write("missing preview: \(url.path)\n".data(using: .utf8)!)
        exit(1)
    }
    return rep
}

for shot in shots {
    // RGBX without alpha: App Store Connect rejects screenshots with transparency.
    let ctx = CGContext(data: nil, width: Int(canvas.width), height: Int(canvas.height), bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let gc = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.current = gc
    gc.imageInterpolation = .high

    // Background: soft diagonal gradient, top-left to bottom-right.
    let (from, to) = shot.dark ? (color(0x1C1F26), color(0x2B3140)) : (color(0xEEF2F7), color(0xD9E3F0))
    NSGradient(starting: from, ending: to)!.draw(in: NSRect(origin: .zero, size: canvas), angle: -35)

    // Caption: one centred line in the system display font, sitting at the top margin.
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: captionSize, weight: .semibold),
        .foregroundColor: shot.dark ? color(0xF5F5F7) : color(0x1D1D1F),
    ]
    let caption = NSAttributedString(string: shot.caption, attributes: attrs)
    let textSize = caption.size()
    let textTop = canvas.height - margin
    caption.draw(at: NSPoint(x: (canvas.width - textSize.width) / 2, y: textTop - textSize.height))

    // Panels: laid out side by side at 1:1 pixels, scaled down together only if
    // the row would overflow the margins, then centred in the space left under
    // the caption.
    let panels = shot.panels.map(loadPanel)
    let rowWidth = panels.reduce(CGFloat(0)) { $0 + CGFloat($1.pixelsWide) } + panelGap * CGFloat(panels.count - 1)
    let rowHeight = panels.map { CGFloat($0.pixelsHigh) }.max()!
    let availHeight = textTop - textSize.height - captionGap - margin
    let scale = min(1, (canvas.width - 2 * margin) / rowWidth, availHeight / rowHeight)
    var x = (canvas.width - rowWidth * scale) / 2
    let rowBottom = margin + (availHeight - rowHeight * scale) / 2

    for panel in panels {
        let size = CGSize(width: CGFloat(panel.pixelsWide) * scale, height: CGFloat(panel.pixelsHigh) * scale)
        // Each panel is bottom-aligned within the row so a shorter one does not float.
        let rect = NSRect(x: x, y: rowBottom, width: size.width, height: size.height)
        gc.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
        shadow.shadowBlurRadius = 40
        shadow.shadowOffset = NSSize(width: 0, height: -20)
        shadow.set()
        // Draw the raw CGImage: unlike NSImage/NSImageRep drawing it has no
        // notion of the 144 dpi tag, so the pixel rect maps 1:1.
        ctx.draw(panel.cgImage!, in: rect)
        gc.restoreGraphicsState()
        x += size.width + panelGap * scale
    }

    NSGraphicsContext.current = nil
    let png = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
    let out = outDir.appendingPathComponent(shot.file)
    try png.write(to: out)
    print("wrote \(out.path)")
}
