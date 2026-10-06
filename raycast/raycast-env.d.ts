/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** iPhoneFrame Project Folder - Folder containing bin/iphoneframe and frame.json. */
  "projectDirectory": string,
  /** Screenshot Fit - Preserve all content or crop to fill the display. */
  "fit": "contain" | "fill"
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `frame-clipboard` command */
  export type FrameClipboard = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `frame-clipboard` command */
  export type FrameClipboard = {}
}
