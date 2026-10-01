// Generates the menu bar icon from the app logo, keeping its original colors (PRD-0006).
//
// Usage: swift scripts/make-menubar-icon.swift
//
// The logo is cropped to the fish and scaled to menu bar height at 1x and 2x.
import AppKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let source = root.appendingPathComponent("docs/images/locus-icon.png")
let outputDir = root.appendingPathComponent("Support/MenuBar")
let heightInPoints: CGFloat = 16

guard let data = try? Data(contentsOf: source), let logo = NSBitmapImageRep(data: data) else {
    fatalError("Can't read \(source.path)")
}

// Bounding box of the opaque pixels, so the fish fills the icon height.
var minX = logo.pixelsWide, minY = logo.pixelsHigh, maxX = 0, maxY = 0
for y in 0..<logo.pixelsHigh {
    for x in 0..<logo.pixelsWide where (logo.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 {
        minX = min(minX, x)
        minY = min(minY, y)
        maxX = max(maxX, x)
        maxY = max(maxY, y)
    }
}
let crop = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
guard let cropped = logo.cgImage?.cropping(to: crop) else { fatalError("Crop failed") }
let widthInPoints = (heightInPoints * crop.width / crop.height).rounded()

for scale in [1, 2] {
    let width = Int(widthInPoints) * scale
    let height = Int(heightInPoints) * scale
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("Context failed") }
    context.interpolationQuality = .high
    context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))

    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    rep.size = NSSize(width: widthInPoints, height: heightInPoints)
    let name = scale == 1 ? "MenuBarIcon.png" : "MenuBarIcon@\(scale)x.png"
    try! rep.representation(using: .png, properties: [:])!.write(to: outputDir.appendingPathComponent(name))
    print("Wrote Support/MenuBar/\(name) (\(width)×\(height) px)")
}
