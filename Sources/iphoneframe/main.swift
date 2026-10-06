import Foundation
import AppKit
import CoreGraphics
import IPhoneFrameCore

let help = """
Usage: iphoneframe [input.png] [-o output.png] [--config frame.json]
       [--frame bezel.png] [--fit contain|fill] [--no-shadow]

Config defaults to IPHONEFRAME_CONFIG, then ./frame.json if present,
then ~/.config/iphoneframe/frame.json.
Relative frame paths resolve beside the JSON file. --frame overrides that path.
Omit input.png to read an image from the clipboard.
Default: copy the framed image to the clipboard without creating a file.
Use -o to save a PNG instead. Portrait/landscape is detected automatically.
Contain preserves all content with black letterboxing; fill crops centrally.
Apple marketing artwork must use --no-shadow. See README for asset terms.
"""

func readClipboardImage() throws -> CGImage {
    let clipboard = NSPasteboard.general
    // Screenshot capture and image copy normally offer PNG or TIFF. Decode in memory.
    for type in [NSPasteboard.PasteboardType.png, .tiff, NSPasteboard.PasteboardType("public.jpeg")] {
        if let data = clipboard.data(forType: type), let image = try? Compositor.readImage(data: data) {
            return image
        }
    }
    // Also accept an image file copied in Finder, without creating a temporary file.
    if let files = clipboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
        for file in files {
            if let image = try? Compositor.readImage(at: file) { return image }
        }
    }
    throw FrameError("No readable image on the clipboard. Copy a screenshot or image first, or pass its file path. Clipboard images have the same size limits as files.")
}

do {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.contains("--help") || args.contains("-h") { print(help); exit(0) }
    var input: String?, output: String?, configPath: String?, framePath: String?
    var options = RenderOptions()
    var i = 0
    while i < args.count {
        let arg = args[i]
        switch arg {
        case "-o", "--config", "--frame", "--fit":
            guard i + 1 < args.count else { throw FrameError("Missing value for \(arg)") }
            i += 1; let value = args[i]
            switch arg {
            case "-o": output = value
            case "--config": configPath = value
            case "--frame": framePath = value
            default:
                guard let fit = Fit(rawValue: value) else { throw FrameError("--fit must be contain or fill.") }
                options.fit = fit
            }
        case "--no-shadow": options.shadow = false
        default:
            guard !arg.hasPrefix("-"), input == nil else { throw FrameError("Unexpected argument: \(arg)") }
            input = arg
        }
        i += 1
    }
    func url(_ path: String) -> URL {
        URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardizedFileURL
    }
    let inputURL = input.map(url)
    let outputURL = output.map(url)
    let configurationURL = url(configPath ?? ProcessInfo.processInfo.environment["IPHONEFRAME_CONFIG"]
                              ?? (FileManager.default.fileExists(atPath: "frame.json") ? "frame.json" : "~/.config/iphoneframe/frame.json"))
    guard FileManager.default.fileExists(atPath: configurationURL.path) else {
        throw FrameError("Missing frame config: \(configurationURL.path). See README to add a local bezel PNG and screen geometry.")
    }
    var config = try FrameConfiguration.load(from: configurationURL)
    if let framePath { config.frame = url(framePath).path; config.landscape = nil }
    if let outputURL {
        guard inputURL.map({ $0.resolvingSymlinksInPath() != outputURL.resolvingSymlinksInPath() }) ?? true,
              url(config.frame).resolvingSymlinksInPath() != outputURL.resolvingSymlinksInPath(),
              configurationURL.resolvingSymlinksInPath() != outputURL.resolvingSymlinksInPath(),
              config.landscape.map({ url($0.frame).resolvingSymlinksInPath() != outputURL.resolvingSymlinksInPath() }) ?? true
        else { throw FrameError("Output must not overwrite the input, frame asset, or config.") }
    }
    let screenshot: CGImage
    if let inputURL {
        screenshot = try Compositor.readImage(at: inputURL)
    } else {
        screenshot = try readClipboardImage()
    }
    let image = try Compositor.renderScreenshot(screenshot: screenshot, configuration: config, options: options)
    if let outputURL {
        try Compositor.writePNG(image, to: outputURL)
        print(outputURL.path)
    } else {
        let png = try Compositor.pngData(image)
        let item = NSPasteboardItem()
        guard item.setData(png, forType: .png) else {
            throw FrameError("Cannot prepare clipboard PNG.")
        }
        // TIFF is offered too for native apps that request it. Both preserve alpha.
        if let tiff = NSBitmapImageRep(cgImage: image).representation(using: .tiff, properties: [:]) {
            item.setData(tiff, forType: .tiff)
        }
        let clipboard = NSPasteboard.general
        clipboard.clearContents()
        guard clipboard.writeObjects([item]) else {
            throw FrameError("Cannot write the system clipboard. Run in your logged-in macOS session.")
        }
        print("Copied framed image to clipboard.")
    }
} catch {
    FileHandle.standardError.write(Data("iphoneframe: \(error.localizedDescription)\n".utf8))
    exit(1)
}
