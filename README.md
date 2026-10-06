# iPhoneFrame

A small macOS Swift package that puts a mobile screenshot inside a locally supplied black iPhone 18 Pro frame and copies the transparent framed image to your clipboard. Use `-o` to save a PNG instead. The library uses CoreGraphics and ImageIO. There are no external dependencies, network calls or Raycast dependencies. Clipboard output uses AppKit in the executable.

Frame artwork is not included. Add a frame that you have permission to use, then configure its display coordinates. The included `frame.json` is calibrated for black iPhone 18 Pro portrait and landscape PNGs with the filenames and dimensions listed below. The JSON under `Examples/` is a synthetic geometry template for other exports.

Copy a screenshot, then run from this project directory:

```sh
./bin/iphoneframe
```

The command reads the clipboard image, frames it, and copies the result back. Paste with Command-V. No input or output image file is created. It accepts PNG, TIFF, JPEG image data and image files copied from Finder. An empty or text-only clipboard returns an error and leaves the clipboard unchanged. Capture or copy a fresh screenshot before each run; running twice will frame the previous result again.

Explicit file input and output remain available:

```sh
./bin/iphoneframe ~/Downloads/screenshot.png
./bin/iphoneframe -o output.png
./bin/iphoneframe input.png -o output.png
```

The configured display rectangle is 1206 × 2622 at x=72, y=69 in the 1350 × 2760 portrait asset. The supplied 2760 × 1350 landscape asset uses a 2622 × 1206 display at x=69, y=72. A 180-pixel clipping radius extends beneath the opaque corner artwork, which supplies the exact visible display curve. Shadow is disabled in this Apple-artwork profile.

## Build and run

Requires macOS 13 or later and Xcode Command Line Tools with Swift 5.9 or later.

```sh
swift build -c release
.build/release/iphoneframe input.png -o output.png --config /absolute/path/frame.json
```

A tested Apple Silicon release executable is included at `bin/iphoneframe`. Rebuild from source on Intel Macs or when you change the code.

For the shorter command, copy `.build/release/iphoneframe` into a directory already on your PATH. No package resources need to travel with it. The CLI uses `--config` first, then `IPHONEFRAME_CONFIG`, then `frame.json` in the current directory, then `~/.config/iphoneframe/frame.json`.

```sh
iphoneframe input.png -o output.png
iphoneframe input.png --fit fill
iphoneframe input.png --no-shadow
iphoneframe input.png --config ./frame.json --frame ./another-export.png
```

The default copies the image to the macOS clipboard as PNG and TIFF, preserving transparency. It creates no file, including no temporary image file. Paste with Command-V in Google Slides or another app. `-o output.png` selects file output instead of changing the clipboard. Output paths must have an existing parent directory. Paths containing spaces need shell quotes. The CLI prints a clipboard confirmation or the explicit output path, sends errors to stderr, and exits with status 1 on failure. Existing output files are replaced atomically; it refuses to overwrite the input or frame.

## Add the frame locally

1. Choose frame artwork whose license permits your intended use. One possible source is [Apple Design Resources, Product Bezels](https://developer.apple.com/design/resources/#product-bezels). If you use Apple's artwork, read and follow the applicable download license agreement and usage guidelines. See the licensing section below. You can also use an independently licensed frame.
2. Use a straight-on portrait PNG with the full chassis, all side controls, and transparent space outside the device. The screen opening must be transparent, with the bezel and Dynamic Island in the foreground layer. A flattened PNG containing a wallpaper will cover your screenshot. If only a PSD supplies the needed layers, export an overlay with its screen content hidden under the applicable asset terms. The tool cannot read PSD files or extract their layers.
3. Keep the artwork in `LocalAssets/`, which Git ignores. To use the included profile, supply `iPhone 18 Pro - Black - Portrait.png` and `iPhone 18 Pro - Black - Landscape.png` with the exact dimensions listed above. For another export, copy `Examples/frame.template.json` to a new config and set its `frame` path. Relative paths resolve beside the JSON. Absolute paths also work.
4. Replace every geometry value with measurements from **that exact PNG export**. `screen.x` and `screen.y` locate the display rectangle's top-left corner. `width` and `height` are the entire display rectangle, including the rounded corners. All values are image pixels, not points or percentages. `cornerRadius` is the display corner radius in the same units. Include any transparent padding in your coordinate measurements. The template's 100 × 200 fixture measurements are deliberately small and must not be used for Apple artwork.
5. Set `shadow` to `false` for Apple marketing artwork. For an asset you have rights to modify, set it to `true` to add the subtle shadow. The compositor always preserves transparent outer padding.
6. Render a screenshot with distinct content near every edge and inspect alignment at full size. Confirm the complete chassis remains visible, all rounded corners fit, and the Island sits over the screenshot. Save that one calibrated config for subsequent captures.

The selected model is fixed through this configuration. There is no device catalogue or automatic frame matching. This local profile was measured from the user-supplied files named `iPhone 18 Pro - Black - Portrait.png` and `iPhone 18 Pro - Black - Landscape.png` on October 5, 2026. File names identify the chosen model; this project has not independently authenticated the files' provenance. Both PNGs have transparent outer canvases and display openings. The calibrated display rectangle is 1206 × 2622 pixels.

## Rendering behavior

- EXIF orientation is normalized before dimension detection. Width greater than height selects landscape; square images select portrait.
- When `landscape` is configured, landscape input uses that supplied artwork directly. In the local black profile, the Island is on the left. Without a separate landscape asset, the library rotates the portrait frame clockwise and the Island moves to the right. The screenshot remains upright in both cases. `--frame` clears the configured landscape override and uses only the supplied override asset.
- `contain` is the default. It preserves screenshot proportions and all content, adding black letterboxing when proportions differ. `fill` preserves proportions and crops centrally to cover the display. Neither option stretches the screenshot.
- The screenshot is clipped to the rounded screen rectangle. The full frame overlays it, so its Island and chassis remain visible. The compositor does not draw a second Island, status bar, or home indicator.
- Output is an 8-bit sRGB PNG with alpha and transparent breathing room. The shadow uses the complete device silhouette. Source metadata is omitted. HDR and wide-gamut colors are converted to sRGB for slide use.
- Decoding and output allocation are limited to 40 megapixels and 12000 pixels per edge. The primary frame should be portrait; an optional `landscape` object supplies a landscape frame, screen rectangle, and corner radius. Use a smaller export if a source or the padded output exceeds these bounds.

AirDrop a real iPhone screenshot, run the CLI, and paste into Google Slides with Command-V. A clean browser viewport capture also works; the tool cannot remove DevTools from a screenshot that already contains them.

## Frame artwork licensing

Frame artwork is not bundled or licensed by this project. You may obtain a suitable asset from [Apple Design Resources](https://developer.apple.com/design/resources/#product-bezels) or another source, provided its terms permit your intended use.

If you choose Apple artwork, you must review and comply with the license agreement supplied with the download and the applicable [Marketing Resources and Identity Guidelines](https://developer.apple.com/app-store/marketing/guidelines/). Check that your use case is permitted, including any restrictions on screen content, modification, shadows, rotation, and redistribution. Apple's artwork is proprietary; the software's ability to render an image does not grant permission to use it. The exact download agreement takes precedence, and this project does not accept it on your behalf.

The included profile disables added shadows and uses a separate landscape asset. Those settings alone do not establish license compliance. Keep artwork out of source control unless its license expressly permits redistribution. Apple and iPhone are trademarks of Apple Inc. This project is independent of Apple.

## Local tests

```sh
swift test
./Scripts/smoke-test.sh
```

Tests create original synthetic rectangles in memory. They check portrait and landscape pixel placement, foreground occlusion, transparent corners, letterboxing versus cropping, shadow alpha, EXIF normalization, invalid geometry, and PNG round-trip. These fixtures are not iPhone artwork and do not establish alignment with an official bezel.

To exercise the CLI without Apple artwork:

```sh
IPHONEFRAME_FIXTURES="$PWD/LocalAssets/test" swift test
swift run iphoneframe LocalAssets/test/portrait.png -o LocalAssets/test/portrait-framed.png --config LocalAssets/test/fixture.json
swift run iphoneframe LocalAssets/test/landscape.png -o LocalAssets/test/landscape-framed.png --config LocalAssets/test/fixture.json
```

`LocalAssets/` is ignored so private artwork and generated fixtures stay out of source control.

## Library and Raycast extension

`IPhoneFrameCore` owns decoding, configuration, orientation, rendering, and PNG writing. The executable handles arguments, paths, and AppKit clipboard output. The core can render a CGImage or return PNG data without writing a file.

```swift
import IPhoneFrameCore
let config = try FrameConfiguration.load(from: configurationURL)
try Compositor.frameScreenshot(input: inputURL, output: outputURL,
    configuration: config, options: RenderOptions(fit: .contain))
```

A Raycast extension can invoke the compiled executable with an argument array and use the default clipboard behavior. Pass `-o` if the extension needs a saved file and read stdout for its path. A native macOS wrapper can call the library directly. A local Raycast extension is included in `raycast/`. See its README for setup and the **Frame Clipboard as iPhone** command.
