import XCTest
import CoreGraphics
import ImageIO
@testable import IPhoneFrameCore

final class CompositorTests: XCTestCase {
    func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [red, green, blue, 1])!
    }
    func bitmap(_ w: Int, _ h: Int, draw: (CGContext) -> Void) -> CGImage {
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
            bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        draw(ctx); return ctx.makeImage()!
    }
    func pixel(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        let ctx = CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        let index = (y * image.width + x) * 4
        return Array(UnsafeBufferPointer(start: bytes + index, count: 4))
    }
    var config: FrameConfiguration {
        .init(frame: "fixture.png", screen: .init(x: 10, y: 10, width: 80, height: 180), cornerRadius: 8)
    }
    var frame: CGImage {
        bitmap(100, 200) { ctx in
            ctx.setFillColor(CGColor(gray: 0.2, alpha: 1))
            ctx.fill(CGRect(x: 2, y: 2, width: 96, height: 196))
            ctx.clear(CGRect(x: 10, y: 10, width: 80, height: 180))
            // Asymmetric marker verifies rotation: top-left of portrait => top-right of landscape.
            ctx.setFillColor(rgb(0, 1, 0))
            ctx.fill(CGRect(x: 2, y: 190, width: 8, height: 8))
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.fill(CGRect(x: 40, y: 178, width: 20, height: 8))
        }
    }
    func testPortraitTransparencyOverlayAndPNG() throws {
        let input = bitmap(80, 180) { ctx in
            ctx.setFillColor(rgb(1, 0, 0))
            ctx.fill(CGRect(x: 0, y: 0, width: 80, height: 180))
        }
        let output = try Compositor.render(screenshot: input, frame: frame, configuration: config,
                                           options: .init(shadow: false))
        XCTAssertEqual(output.width, 148); XCTAssertEqual(output.height, 248)
        XCTAssertEqual(pixel(output, x: 0, y: 0)[3], 0)
        XCTAssertEqual(pixel(output, x: 74, y: 124), [255, 0, 0, 255])
        XCTAssertEqual(pixel(output, x: 74, y: 42), [0, 0, 0, 255]) // Frame covers screenshot.
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("output.png")
        try Compositor.writePNG(output, to: file)
        let decoded = try Compositor.readImage(at: file)
        XCTAssertEqual(decoded.width, output.width)
        XCTAssertEqual(pixel(decoded, x: 0, y: 0)[3], 0)
    }
    func testLandscapeKeepsScreenshotUprightAndRotatesFrame() throws {
        let input = bitmap(180, 80) { ctx in
            ctx.setFillColor(rgb(1, 0, 0))
            ctx.fill(CGRect(x: 0, y: 0, width: 180, height: 40))
            ctx.setFillColor(rgb(0, 0, 1))
            ctx.fill(CGRect(x: 0, y: 40, width: 180, height: 40))
        }
        let output = try Compositor.render(screenshot: input, frame: frame, configuration: config,
                                           options: .init(shadow: false))
        XCTAssertEqual(output.width, 248); XCTAssertEqual(output.height, 148)
        XCTAssertEqual(pixel(output, x: 124, y: 54), [0, 0, 255, 255])
        XCTAssertEqual(pixel(output, x: 124, y: 94), [255, 0, 0, 255])
        XCTAssertEqual(pixel(output, x: 218, y: 30), [0, 255, 0, 255])
    }
    func testContainFillAndShadow() throws {
        let input = bitmap(60, 60) { ctx in
            ctx.setFillColor(rgb(1, 0, 0))
            ctx.fill(CGRect(x: 0, y: 0, width: 60, height: 60))
        }
        let contain = try Compositor.render(screenshot: input, frame: frame, configuration: config,
                                            options: .init(shadow: false))
        let fill = try Compositor.render(screenshot: input, frame: frame, configuration: config,
                                         options: .init(fit: .fill, shadow: false))
        XCTAssertEqual(pixel(contain, x: 74, y: 64), [0, 0, 0, 255])
        XCTAssertEqual(pixel(fill, x: 74, y: 64), [255, 0, 0, 255])
        let shadow = try Compositor.render(screenshot: input, frame: frame, configuration: config)
        XCTAssertEqual(pixel(contain, x: 25, y: 124)[3], 0)
        XCTAssertGreaterThan(pixel(shadow, x: 25, y: 124)[3], 0)
        XCTAssertEqual(pixel(shadow, x: 0, y: 0)[3], 0)
    }
    func testNativeLandscapeAssetAndRelativePaths() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let native = bitmap(200, 100) { ctx in
            ctx.setFillColor(CGColor(gray: 0.2, alpha: 1))
            ctx.fill(CGRect(x: 2, y: 2, width: 196, height: 96))
            ctx.clear(CGRect(x: 10, y: 10, width: 180, height: 80))
            ctx.setFillColor(rgb(0, 1, 0))
            ctx.fill(CGRect(x: 2, y: 90, width: 8, height: 8))
        }
        let input = bitmap(180, 80) { ctx in
            ctx.setFillColor(rgb(1, 0, 0))
            ctx.fill(CGRect(x: 0, y: 0, width: 180, height: 80))
        }
        try Compositor.writePNG(native, to: folder.appendingPathComponent("native.png"))
        try Compositor.writePNG(input, to: folder.appendingPathComponent("input.png"))
        var c = config
        c.shadow = false
        c.landscape = .init(frame: "native.png", screen: .init(x: 10, y: 10, width: 180, height: 80), cornerRadius: 8)
        let configURL = folder.appendingPathComponent("frame.json")
        try JSONEncoder().encode(c).write(to: configURL)
        let loaded = try FrameConfiguration.load(from: configURL)
        XCTAssertEqual(loaded.landscape?.frame, folder.appendingPathComponent("native.png").path)
        // The missing portrait asset proves that this selects the supplied landscape asset.
        let outputURL = folder.appendingPathComponent("output.png")
        try Compositor.frameScreenshot(input: folder.appendingPathComponent("input.png"),
                                       output: outputURL, configuration: loaded)
        let output = try Compositor.readImage(at: outputURL)
        XCTAssertEqual(output.width, 248); XCTAssertEqual(output.height, 148)
        XCTAssertEqual(pixel(output, x: 30, y: 30), [0, 255, 0, 255])
        XCTAssertEqual(pixel(output, x: 124, y: 74), [255, 0, 0, 255])
    }
    func testEXIFOrientationIsNormalized() throws {
        let image = bitmap(60, 100) { ctx in
            ctx.setFillColor(CGColor(gray: 0.5, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: 60, height: 100))
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("rotated.jpg")
        let encoder = CGImageDestinationCreateWithURL(file as CFURL, "public.jpeg" as CFString, 1, nil)!
        CGImageDestinationAddImage(encoder, image, [kCGImagePropertyOrientation: 6] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(encoder))
        let normalized = try Compositor.readImage(at: file)
        XCTAssertEqual(normalized.width, 100)
        XCTAssertEqual(normalized.height, 60)
        let memoryImage = try Compositor.readImage(data: Data(contentsOf: file))
        XCTAssertEqual(memoryImage.width, 100)
        XCTAssertEqual(memoryImage.height, 60)
        XCTAssertThrowsError(try Compositor.readImage(data: Data("not an image".utf8)))
    }
    func testRejectInvalidGeometry() {
        var bad = config; bad.screen.width = 1000
        XCTAssertThrowsError(try Compositor.render(screenshot: frame, frame: frame, configuration: bad))
        bad = config; bad.cornerRadius = -1
        XCTAssertThrowsError(try Compositor.render(screenshot: frame, frame: frame, configuration: bad))
    }
    func testGenerateLocalFixturesWhenRequested() throws {
        guard let path = ProcessInfo.processInfo.environment["IPHONEFRAME_FIXTURES"] else { return }
        let folder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Compositor.writePNG(frame, to: folder.appendingPathComponent("fixture-frame.png"))
        var c = config; c.frame = "fixture-frame.png"
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(c).write(to: folder.appendingPathComponent("fixture.json"))
        for (name, w, h) in [("portrait", 80, 180), ("landscape", 180, 80)] {
            let input = bitmap(w, h) { ctx in
                ctx.setFillColor(rgb(0.12, 0.5, 0.9))
                ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
                ctx.setFillColor(CGColor(gray: 1, alpha: 1))
                ctx.fill(CGRect(x: 15, y: 20, width: w - 30, height: 20))
            }
            try Compositor.writePNG(input, to: folder.appendingPathComponent(name + ".png"))
        }
    }
}
