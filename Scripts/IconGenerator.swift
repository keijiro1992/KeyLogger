#!/usr/bin/swift
import Cocoa
import Foundation

/// Generates app icons for KeyLogger app using SF Symbols
/// Run: swift Scripts/IconGenerator.swift

let sizes: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func generateIcon(size: Int) -> NSImage {
    // Create bitmap with exact pixel dimensions
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmapRep.size = NSSize(width: size, height: size)
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
    
    // Background gradient (purple to blue)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0),
        NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
    ])!
    
    // Rounded rectangle background
    let cornerRadius = CGFloat(size) * 0.2
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    gradient.draw(in: path, angle: -45)
    
    // Draw keyboard symbol using SF Symbols
    if let symbolImage = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil) {
        let symbolSize = CGFloat(size) * 0.5
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
        let configuredSymbol = symbolImage.withSymbolConfiguration(symbolConfig)!
        
        // Get the actual symbol size
        let actualSymbolSize = configuredSymbol.size
        let x = (CGFloat(size) - actualSymbolSize.width) / 2
        let y = (CGFloat(size) - actualSymbolSize.height) / 2
        
        // Draw with white tint
        let tintedSymbol = NSImage(size: actualSymbolSize)
        tintedSymbol.lockFocus()
        configuredSymbol.draw(in: NSRect(origin: .zero, size: actualSymbolSize))
        NSColor.white.set()
        NSRect(origin: .zero, size: actualSymbolSize).fill(using: .sourceAtop)
        tintedSymbol.unlockFocus()
        
        tintedSymbol.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 0.95)
    }
    
    NSGraphicsContext.restoreGraphicsState()
    
    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmapRep)
    return image
}

func saveIconAsPNG(_ image: NSImage, to url: URL) {
    guard let bitmapRep = image.representations.first as? NSBitmapImageRep,
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(url.lastPathComponent)")
        return
    }
    
    do {
        try pngData.write(to: url)
        print("✓ Created: \(url.lastPathComponent) [\(bitmapRep.pixelsWide)x\(bitmapRep.pixelsHigh)]")
    } catch {
        print("✗ Failed to save \(url.lastPathComponent): \(error)")
    }
}

// Main execution
let scriptPath = URL(fileURLWithPath: #file)
let projectRoot = scriptPath.deletingLastPathComponent().deletingLastPathComponent()
let iconsetPath = projectRoot
    .appendingPathComponent("KeyLogger")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

print("Generating icons to: \(iconsetPath.path)")

// Ensure directory exists
try? FileManager.default.createDirectory(at: iconsetPath, withIntermediateDirectories: true)

for (name, size) in sizes {
    let icon = generateIcon(size: size)
    let url = iconsetPath.appendingPathComponent(name)
    saveIconAsPNG(icon, to: url)
}

print("\n✅ Icon generation complete!")
