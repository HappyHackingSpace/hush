import AppKit

// Renders the 1024x1024 master app icon: a dark squircle with a notch and stacked script lines,
// the middle line tinted to evoke the highlighted word. Run: swift scripts/make-icon.swift
let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

let rect = CGRect(x: 0, y: 0, width: size, height: size)
let squircle = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
squircle.addClip()

let colors = [NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.18, alpha: 1).cgColor,
              NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// Notch at top center.
let notchWidth = size * 0.30
let notchHeight = size * 0.075
let notch = NSBezierPath(
    roundedRect: CGRect(x: (size - notchWidth) / 2, y: size - notchHeight - size * 0.02,
                        width: notchWidth, height: notchHeight),
    xRadius: notchHeight / 2, yRadius: notchHeight / 2
)
NSColor.black.setFill()
notch.fill()

// Script lines.
let lineHeight = size * 0.085
let widths = [0.56, 0.66, 0.46]
let tints = [NSColor.white.withAlphaComponent(0.85),
             NSColor(calibratedRed: 0.39, green: 0.55, blue: 1.0, alpha: 1.0),
             NSColor.white.withAlphaComponent(0.85)]
for (index, ratio) in widths.enumerated() {
    let width = size * ratio
    let y = size * 0.56 - Double(index) * (lineHeight + size * 0.045)
    let bar = NSBezierPath(
        roundedRect: CGRect(x: (size - width) / 2, y: y, width: width, height: lineHeight),
        xRadius: lineHeight / 2, yRadius: lineHeight / 2
    )
    tints[index].setFill()
    bar.fill()
}

image.unlockFocus()

let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon_1024.png")
try! png.write(to: out)
print("wrote \(out.path)")
