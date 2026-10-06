import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct FrameError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

/// Pixel coordinates measured from the top-left of the unrotated frame PNG.
public struct ScreenRect: Codable {
    public var x, y, width, height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public struct LandscapeFrame: Codable {
    public var frame: String
    public var screen: ScreenRect
    public var cornerRadius: Double
    public init(frame: String, screen: ScreenRect, cornerRadius: Double) {
        self.frame = frame; self.screen = screen; self.cornerRadius = cornerRadius
    }
}

public struct FrameConfiguration: Codable {
    public var model: String
    public var frame: String
    public var screen: ScreenRect
    public var cornerRadius: Double
    public var shadow: Bool
    public var landscape: LandscapeFrame?
    public init(model: String = "iPhone 17 Pro", frame: String, screen: ScreenRect,
                cornerRadius: Double, shadow: Bool = true, landscape: LandscapeFrame? = nil) {
        self.model = model; self.frame = frame; self.screen = screen
        self.cornerRadius = cornerRadius; self.shadow = shadow; self.landscape = landscape
    }
    public static func load(from url: URL) throws -> FrameConfiguration {
        var config = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        if !config.frame.hasPrefix("/") {
            config.frame = url.deletingLastPathComponent().appendingPathComponent(config.frame).path
        }
        if let path = config.landscape?.frame, !path.hasPrefix("/") {
            config.landscape?.frame = url.deletingLastPathComponent().appendingPathComponent(path).path
        }
        return config
    }
}

public enum Fit: String { case contain, fill }
public struct RenderOptions {
    public var fit: Fit = .contain
    public var shadow: Bool? = nil
    public init(fit: Fit = .contain, shadow: Bool? = nil) {
        self.fit = fit; self.shadow = shadow
    }
}

public enum Compositor {
    // Bounds prevent integer overflow and unexpectedly large bitmap allocations.
    private static func context(width: Int, height: Int) throws -> CGContext {
        guard width > 0, height > 0, width <= 12000, height <= 12000,
              width * height <= 40_000_000,
              let color = CGColorSpace(name: CGColorSpace.sRGB),
              let ctx = CGContext(data: nil, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: color,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw FrameError("Image exceeds the 40 megapixel / 12000 pixel limit, or bitmap allocation failed.") }
        ctx.interpolationQuality = .high
        return ctx
    }

    /// ImageIO normalizes EXIF orientation before orientation detection.
    public static func readImage(at url: URL) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw FrameError("Cannot read image: \(url.path)")
        }
        return try decodeImage(source)
    }

    public static func readImage(data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw FrameError("Cannot read clipboard image data.")
        }
        return try decodeImage(source)
    }

    private static func decodeImage(_ source: CGImageSource) throws -> CGImage {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int,
              w > 0, h > 0, w <= 12000, h <= 12000, w * h <= 40_000_000,
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(w, h)
              ] as CFDictionary)
        else { throw FrameError("Cannot decode image or image exceeds the 40 megapixel / 12000 pixel limits.") }
        return image
    }

    public static func render(screenshot: CGImage, frame: CGImage,
                              configuration c: FrameConfiguration,
                              options: RenderOptions = RenderOptions()) throws -> CGImage {
        let s = c.screen
        let values = [s.x, s.y, s.width, s.height, c.cornerRadius]
        guard values.allSatisfy({ $0.isFinite }), s.x >= 0, s.y >= 0,
              s.width > 0, s.height > 0, s.x + s.width <= Double(frame.width),
              s.y + s.height <= Double(frame.height), c.cornerRadius >= 0,
              c.cornerRadius <= min(s.width, s.height) / 2,
              frame.height > frame.width || screenshot.width > screenshot.height
        else { throw FrameError("Invalid screen bounds/radius. Supply top-left pixel coordinates and a frame matching the orientation.") }
        let landscape = screenshot.width > screenshot.height // Square inputs use portrait.
        let rotateFrame = landscape && frame.height > frame.width
        let fw = rotateFrame ? frame.height : frame.width
        let fh = rotateFrame ? frame.width : frame.height
        let rect = rotateFrame
            ? CGRect(x: Double(frame.height) - s.y - s.height, y: s.x, width: s.height, height: s.width)
            : CGRect(x: s.x, y: s.y, width: s.width, height: s.height)
        // Convert the top-left configuration to CoreGraphics' bottom-left origin.
        let screen = CGRect(x: rect.minX, y: CGFloat(fh) - rect.maxY, width: rect.width, height: rect.height)
        let device = try context(width: fw, height: fh)
        let clip = CGPath(roundedRect: screen, cornerWidth: c.cornerRadius,
                          cornerHeight: c.cornerRadius, transform: nil)
        device.addPath(clip); device.setFillColor(CGColor(gray: 0, alpha: 1)); device.fillPath()
        device.saveGState(); device.addPath(clip); device.clip()
        let sx = screen.width / CGFloat(screenshot.width), sy = screen.height / CGFloat(screenshot.height)
        let scale = options.fit == .contain ? min(sx, sy) : max(sx, sy)
        let size = CGSize(width: CGFloat(screenshot.width) * scale, height: CGFloat(screenshot.height) * scale)
        device.draw(screenshot, in: CGRect(x: screen.midX - size.width / 2,
                    y: screen.midY - size.height / 2, width: size.width, height: size.height))
        device.restoreGState()
        device.saveGState()
        if rotateFrame {
            device.translateBy(x: 0, y: CGFloat(fh)); device.rotate(by: -.pi / 2)
        }
        device.draw(frame, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        device.restoreGState()
        guard let layer = device.makeImage() else { throw FrameError("Cannot create device bitmap.") }
        // Shadow comes from the complete device silhouette, never its screen opening.
        let blur = max(3, CGFloat(min(fw, fh)) * 0.018)
        let offset = blur * 0.6
        let padding = Int(ceil(max(24, blur * 4 + offset)))
        let output = try context(width: fw + padding * 2, height: fh + padding * 2)
        if options.shadow ?? c.shadow {
            output.setShadow(offset: CGSize(width: 0, height: -offset), blur: blur,
                             color: CGColor(gray: 0, alpha: 0.22))
        }
        output.draw(layer, in: CGRect(x: padding, y: padding, width: fw, height: fh))
        guard let result = output.makeImage() else { throw FrameError("Cannot create output bitmap.") }
        return result
    }

    public static func pngData(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let encoder = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw FrameError("PNG encoder unavailable.") }
        CGImageDestinationAddImage(encoder, image, nil)
        guard CGImageDestinationFinalize(encoder) else { throw FrameError("PNG encoding failed.") }
        return data as Data
    }

    public static func writePNG(_ image: CGImage, to url: URL) throws {
        // Atomic writes preserve an existing output if encoding fails.
        try pngData(image).write(to: url, options: .atomic)
    }

    public static func renderScreenshot(input: URL, configuration: FrameConfiguration,
                                        options: RenderOptions = RenderOptions()) throws -> CGImage {
        try renderScreenshot(screenshot: readImage(at: input), configuration: configuration, options: options)
    }

    public static func renderScreenshot(screenshot: CGImage, configuration: FrameConfiguration,
                                        options: RenderOptions = RenderOptions()) throws -> CGImage {
        var selected = configuration
        if screenshot.width > screenshot.height, let landscape = configuration.landscape {
            selected.frame = landscape.frame
            selected.screen = landscape.screen
            selected.cornerRadius = landscape.cornerRadius
        }
        return try render(screenshot: screenshot,
                          frame: readImage(at: URL(fileURLWithPath: selected.frame)),
                          configuration: selected, options: options)
    }

    public static func frameScreenshot(input: URL, output: URL, configuration: FrameConfiguration,
                                       options: RenderOptions = RenderOptions()) throws {
        try writePNG(renderScreenshot(input: input, configuration: configuration, options: options), to: output)
    }
}
