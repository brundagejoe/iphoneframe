# iPhoneFrame for Raycast

Run **Frame Clipboard as iPhone** to frame the clipboard screenshot with your local black iPhone 18 Pro artwork and copy the result back. Paste with Command-V. Portrait and landscape use the calibrated assets in the Swift project. No image file is created.

## Use

1. Copy a fresh screenshot or an image file from Finder.
2. Open Raycast and search for `Frame Clipboard as iPhone`.
3. Press Return, then paste into Google Slides or another app.

The command shows progress, confirms success, and reports the Swift tool's error if the clipboard has no readable image. Re-running on a framed result frames it again; copy a fresh screenshot first.

In Raycast Settings > Extensions > iPhoneFrame, you can set the project folder and choose whether to preserve all content or crop to fill. The default folder is `~/Documents/projects/iphoneframe`. It must contain `bin/iphoneframe`, `frame.json`, and the PNGs referenced by that config. The native tool controls the shadow setting.

## Raycast Beta

The extension has been tested in **Raycast Beta**, including the clipboard image output. Beta uses a separate extension folder from regular Raycast.

For future source changes, rebuild directly into Beta's registered extension folder:

```sh
cd ~/Documents/projects/iphoneframe/raycast
npm run build:beta
```

This uses the official CLI's `--output` flag to put the executable command in `~/.config/raycast-x/extensions/iphoneframe`. The current CLI's default development target is regular Raycast, so `npm run dev` alone does not update this beta installation.

For a fresh beta installation, run `npm ci` in this folder, sign in to Raycast Beta, run **Import Extension**, select this `raycast` source folder, then run `npm run build:beta`. Import registers the manifest; building supplies the executable command. The Swift binary and frame configuration stay in the main project folder.

## Regular Raycast installation

Requires Raycast, npm, and Node 22.22.2 or later. The extension stays registered when the development watcher is stopped.

```sh
cd ~/Documents/projects/iphoneframe/raycast
npm ci
npm run dev
```

Wait for the successful build, then stop the watcher with Control-C. For source changes, run it again to refresh the installed development command. This is a local extension; no Raycast Store submission or account is needed.

```sh
npm run build
npm run lint
```

Raycast's full Store metadata validation requires a real Raycast author handle. The local manifest currently uses the project owner's name, `joebrundage`, which the Store API does not recognize. For a future Store submission, replace it with the correct account handle. The local lint command checks source and formatting without validating Store identity. Build and TypeScript validation run normally.

## Implementation

The extension runs `bin/iphoneframe --config <project>/frame.json --fit contain|fill` through Node's `execFile` with an argument array, a 30-second timeout, and an explicit project directory. It does not invoke a shell or copy a text path over the image clipboard. Swift handles image reads and writes through AppKit and performs compositing in CoreGraphics. No Apple artwork is bundled in the extension assets; the only bundled image is an original generic command icon.

See the main project README for Apple artwork terms. This wrapper does not expand permission to use those assets.

[Raycast CLI documentation](https://developers.raycast.com/information/developer-tools/cli) describes local import and build. [Raycast HUD documentation](https://developers.raycast.com/api-reference/feedback/hud) describes the success confirmation.
