# Validation

Verified on October 5, 2026 with Apple Swift 6.4 on an Apple Silicon Mac.

- Seven XCTest tests passed in release. They cover portrait and landscape placement, separate landscape assets, transparency, frame occlusion, contain/fill behavior, shadow alpha, EXIF normalization for file and memory input, invalid data/geometry, and PNG round-trip.
- CLI checks passed for PNG and TIFF clipboard input, image files copied from Finder, explicit file input, and PNG file output.
- A text-only clipboard returned an error without changing the clipboard. Default output created no image file.
- Clipboard PNG and TIFF output retained transparent corners.
- The supplied black portrait frame was visually checked with a real screenshot. The display opening contained no unfilled transparent pixels. The separate landscape frame was also checked.
- The Raycast extension passed production build, TypeScript, ESLint, and formatting checks. It was built with the API's supported Node 22.22.2 runtime.
- The command was imported, built, and launched in Raycast Beta. It showed its success confirmation, and the resulting clipboard image was verified.

Private device artwork and generated fixtures are excluded from Git. Asset provenance and archive-specific licensing were not independently verified. Users must follow the license agreement for their chosen artwork. See README for asset setup and licensing links.

Local source lint is separate from Raycast Store metadata validation. A registered Raycast author handle is required before any Store submission. No Store submission was made.
