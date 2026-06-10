import AppKit

// Renders docs/hero.png: a dark banner with the notch + script-line motif, wordmark, tagline.
// Run: swift scripts/make-hero.swift docs/hero.png
let width = 1200.0
let height = 630.0
let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Background gradient.
let bg = [NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.16, alpha: 1).cgColor,
          NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.04, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bg, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [])

// Notch hanging from the top center.
let notchWidth = 240.0
let notchHeight = 30.0
let notch = NSBezierPath(
    roundedRect: CGRect(x: (width - notchWidth) / 2, y: height - notchHeight,
                        width: notchWidth, height: notchHeight + 20),
    xRadius: 16, yRadius: 16
)
NSColor.black.setFill()
notch.fill()

// Overlay card just under the notch.
let cardWidth = 560.0
let cardHeight = 150.0
let cardRect = CGRect(x: (width - cardWidth) / 2, y: height - notchHeight - cardHeight - 28,
                      width: cardWidth, height: cardHeight)
let card = NSBezierPath(roundedRect: cardRect, xRadius: 26, yRadius: 26)
NSColor(calibratedWhite: 0.12, alpha: 0.95).setFill()
card.fill()
NSColor(calibratedWhite: 1, alpha: 0.12).setStroke()
card.lineWidth = 1.5
card.stroke()

// Three script lines inside, middle one tinted (the highlighted word).
let lineHeight = 22.0
let widths = [0.5, 0.62, 0.42]
let tints = [NSColor.white.withAlphaComponent(0.85),
             NSColor(calibratedRed: 0.39, green: 0.55, blue: 1.0, alpha: 1.0),
             NSColor.white.withAlphaComponent(0.85)]
for (index, ratio) in widths.enumerated() {
    let lineWidth = cardWidth * ratio
    let y = cardRect.maxY - 42 - Double(index) * (lineHeight + 18)
    let bar = NSBezierPath(
        roundedRect: CGRect(x: cardRect.midX - lineWidth / 2, y: y, width: lineWidth, height: lineHeight),
        xRadius: lineHeight / 2, yRadius: lineHeight / 2
    )
    tints[index].setFill()
    bar.fill()
}

func draw(_ text: String, font: NSFont, color: NSColor, centerY: Double) {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let string = NSAttributedString(string: text, attributes: attrs)
    let size = string.size()
    string.draw(at: NSPoint(x: (width - size.width) / 2, y: centerY - size.height / 2))
}

draw("Hush", font: .systemFont(ofSize: 96, weight: .bold), color: .white, centerY: 210)
draw("The invisible teleprompter that lives in your notch",
     font: .systemFont(ofSize: 30, weight: .medium),
     color: NSColor(calibratedWhite: 0.7, alpha: 1), centerY: 130)

image.unlockFocus()
let tiff = image.tiffRepresentation!
let png = NSBitmapImageRep(data: tiff)!.representation(using: .png, properties: [:])!
let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/hero.png")
try? FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
try! png.write(to: out)
print("wrote \(out.path)")
