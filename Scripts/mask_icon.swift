import Cocoa

// Apply macOS squircle mask to a user-provided icon image
// Usage: swift mask_icon.swift <input_path> <output_path>

// Squircle corner radius: ~22% of canvas (Apple HIG for macOS Big Sur+)
let cornerRadiusRatio: CGFloat = 0.22

let args = CommandLine.arguments
guard args.count >= 2 else {
    print("Usage: swift mask_icon.swift <input_png_path> [output_iconset_path]")
    exit(1)
}

let inputPath = args[1]
let outputDir: String
if args.count >= 3 {
    outputDir = args[2]
} else {
    outputDir = "AppIcon.iconset"
}

// Load source image
guard let sourceImage = NSImage(contentsOfFile: inputPath) else {
    print("Failed to load image: \(inputPath)")
    exit(1)
}

let canvasSize: CGFloat = 1024
let cornerRadius = canvasSize * cornerRadiusRatio

// Render masked image
let maskedImage = NSImage(size: NSSize(width: canvasSize, height: canvasSize), flipped: false) { rect in
    guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

    // Draw squircle mask
    let bgRect = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
    let maskPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    ctx.addPath(maskPath.cgPath)
    ctx.clip()

    // Draw source image scaled to fill
    sourceImage.draw(in: bgRect)

    // Subtle inner shadow/border
    ctx.resetClip()
    ctx.addPath(maskPath.cgPath)
    ctx.setStrokeColor(CGColor(gray: 0, alpha: 0.06))
    ctx.setLineWidth(1.5)
    ctx.strokePath()

    return true
}

// Create iconset directory
let iconsetURL = URL(fileURLWithPath: outputDir)
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let resized = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        maskedImage.draw(in: rect)
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
    let fileURL = iconsetURL.appendingPathComponent("\(name).png")
    try pngData.write(to: fileURL)
    print("  \(name) (\(Int(size))x\(Int(size)))")
}

print("\nIconset created at: \(iconsetURL.path)")
print("Run: iconutil -c icns AppIcon.iconset")