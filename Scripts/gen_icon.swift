import Cocoa

// Generate a clean macOS app icon for SymLinker
// Following Apple HIG: squircle shape, icon grid bounding box, light visual weight

let canvasSize: CGFloat = 1024

// Squircle corner radius — Apple uses ~22% of icon size for macOS Big Sur+
// Over a 1024px canvas: 1024 * 0.22 = 225
let squircleRadius: CGFloat = 225

// Stroke-based chain link — thinner, lighter visual weight
// Symbol fits within icon grid bounding box (~90% of canvas)

let cx = canvasSize / 2
let cy = canvasSize / 2

let image = NSImage(size: NSSize(width: canvasSize, height: canvasSize), flipped: false) { rect in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    // --- Background: white squircle ---
    let bgRect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: squircleRadius, yRadius: squircleRadius)

    // Subtle shadow for depth
    ctx.setShadow(offset: .zero, blur: 16, color: CGColor(gray: 0, alpha: 0.07))
    ctx.addPath(bgPath.cgPath)
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fillPath()

    // Thin border
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.addPath(bgPath.cgPath)
    ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.06))
    ctx.setLineWidth(1.5)
    ctx.strokePath()
    
    // --- Draw chain links — stroked rounded rects ---
    let linkW: CGFloat = 100
    let linkH: CGFloat = 340
    let linkStrokeW: CGFloat = 28
    let linkGap: CGFloat = 48
    let linkRadius: CGFloat = linkStrokeW / 2 + 4
    let rotationAngle: CGFloat = .pi / 6

    let halfGap = linkGap / 2
    let halfW = linkW / 2
    let halfH = linkH / 2

    let linkColor = CGColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1)

    // Left link
    ctx.saveGState()
    ctx.translateBy(x: cx - halfGap, y: cy)
    ctx.rotate(by: rotationAngle)
    let leftRect = CGRect(x: -halfW, y: -halfH, width: linkW, height: linkH)
    let leftLink = NSBezierPath(roundedRect: leftRect, xRadius: linkRadius, yRadius: linkRadius)
    ctx.addPath(leftLink.cgPath)
    ctx.setStrokeColor(linkColor)
    ctx.setLineWidth(linkStrokeW)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Right link
    ctx.saveGState()
    ctx.translateBy(x: cx + halfGap, y: cy)
    ctx.rotate(by: -rotationAngle)
    let rightRect = CGRect(x: -halfW, y: -halfH, width: linkW, height: linkH)
    let rightLink = NSBezierPath(roundedRect: rightRect, xRadius: linkRadius, yRadius: linkRadius)
    ctx.addPath(rightLink.cgPath)
    ctx.setStrokeColor(linkColor)
    ctx.setLineWidth(linkStrokeW)
    ctx.strokePath()
    ctx.restoreGState()

    // --- Subtle highlight overlay ---
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    let shinePath = NSBezierPath(roundedRect: bgRect, xRadius: squircleRadius, yRadius: squircleRadius)
    ctx.addPath(shinePath.cgPath)
    ctx.clip()
    let shineColors = [CGColor(gray: 1, alpha: 0.08), CGColor(gray: 1, alpha: 0)] as CFArray
    if let shineGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: shineColors, locations: [0, 1]) {
        ctx.drawLinearGradient(shineGradient,
                               start: CGPoint(x: 0, y: canvasSize),
                               end: CGPoint(x: canvasSize * 0.5, y: canvasSize * 0.4),
                               options: [])
    }

    return true
}

// --- Export multi-resolution PNGs ---
let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let resized = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        image.draw(in: rect)
        return true
    }
    guard let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        print("Failed to create CGImage for \(name)")
        continue
    }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG for \(name)")
        continue
    }
    let fileURL = outputDir.appendingPathComponent("\(name).png")
    try pngData.write(to: fileURL)
    print("Generated \(name) (\(Int(size))x\(Int(size)))")
}

print("\nIcon set created at: \(outputDir.path)")
print("Run: iconutil -c icns AppIcon.iconset")