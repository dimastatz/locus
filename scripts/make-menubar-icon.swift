// Generates the menu bar template icon from the app logo.
//
// Usage: swift scripts/make-menubar-icon.swift
//
// The logo's alpha channel becomes a black silhouette (the eye is transparent in the
// logo, so it survives as a cut-out). macOS tints template images to match the menu bar.
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
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("Context failed") }
    context.interpolationQuality = .high
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    // Use the logo as a mask and fill it with black: a silhouette that keeps the alpha edges.
    context.clip(to: rect, mask: alphaMask(of: cropped))
    context.setFillColor(NSColor.black.cgColor)
    context.fill(rect)

    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    rep.size = NSSize(width: widthInPoints, height: heightInPoints)
    let name = scale == 1 ? "MenuBarIcon.png" : "MenuBarIcon@\(scale)x.png"
    try! rep.representation(using: .png, properties: [:])!.write(to: outputDir.appendingPathComponent(name))
    print("Wrote Support/MenuBar/\(name) (\(width)×\(height) px)")
}

/// A grayscale mask from the image's alpha channel (white = opaque).
func alphaMask(of image: CGImage) -> CGImage {
    let width = image.width, height = image.height
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    let alpha = context.makeImage()!
    // alphaOnly images can't be used as masks directly; copy the bytes into a gray image.
    let gray = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: alpha.bytesPerRow,
        space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    gray.data!.copyMemory(from: context.data!, byteCount: alpha.bytesPerRow * height)
    return gray.makeImage()!
}
