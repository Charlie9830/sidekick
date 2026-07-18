# "It's Just a Phase" — App Icon Concepts

Three icon concepts for production desktop releases (Windows MSIX + macOS).
Each concept has two hand-authored master SVGs (1024x1024 viewBox):

- `concept-N-windows.svg` — full-bleed square composition on a filled dark
  background (MSIX tooling handles its own plate/scaling).
- `concept-N-macos.svg` — modern macOS style: rounded-rect "squircle" card
  (corner radius ~22.37% of the card) centered with ~10% transparent margin,
  subtle vertical gradient on the card.

PNG previews at 1024 and 512 were rendered with headless Microsoft Edge
(no ImageMagick/rsvg/Inkscape on this machine); e.g.
`concept-1-windows-512.png`. SVGs are the source of truth.

## Concept 1 — "Three Phases"

Three interleaved sine waves offset by 120 degrees — the literal three-phase
power waveform — in Australian phase colours (red / white / blue) on charcoal.
The thick overlapping strokes form a braid that stays recognisable at 32px as
a bold tricolour weave, and the name pun is instantly legible to anyone in
production electrics. Palette: `#FF4152`, `#F4F6FB`, `#2F80FF` on
`#1B1F27 → #0D0F14`.

## Concept 2 — "Phase Dial"

A powerCON-style connector face: a brushed-steel locking ring with a keyway
gap at the bottom and three amber contact slots arranged at 120 degrees.
Speaks directly to the app's power-patching job and to anyone who has coiled
a cable. One accent colour plus a neutral ring means it survives extreme
downscaling — at 32px it reads as "circle with three marks". Palette: amber
`#FFC94D → #FF8A00`, steel `#F5F7FA → #B9C1CF` on `#191D25 → #0C0E13`.

## Concept 3 — "Phi"

The electrical phase symbol (phi, as in "3-phase") built from pure geometry: a
warm-white ring crossed by a violet-to-blue stroke bent into a gentle sine,
with a faint violet glow. The single bold glyph is the most minimal and
"premium" of the three, pairs well with the app's Orbitron/techy identity, and
its silhouette is unmistakable even at 16px. Palette: `#F4F6FB`,
`#8B5CF6 → #3B82F6` on `#171A22 → #0C0E13`.

## Production follow-up steps

Once a concept is chosen:

1. **Windows (MSIX)**: export the chosen `concept-N-windows.svg` to a 512px
   PNG (the existing headless-Edge command works, or any rasterizer) and point
   `msix_config.logo_path` in `pubspec.yaml` at it (replacing
   `windows_resources/msix_logo_512px.png`). Optionally also export the
   scaled MSIX tile assets (44/150/310px etc.) if bypassing the msix
   package's auto-generation.
2. **macOS (.icns)**: on the Mac, export `concept-N-macos.svg` to PNG at
   16, 32, 64, 128, 256, 512, 1024 (including @2x pairs) into an
   `AppIcon.iconset` folder, then run `iconutil -c icns AppIcon.iconset` and
   replace `macos/Runner/Assets.xcassets/AppIcon.appiconset` contents (or
   drop the sizes straight into the appiconset with a matching
   `Contents.json`).
3. **Small-size pass**: after choosing, test the 32px and 16px renders on
   light and dark taskbars/docks; thicken strokes in the master SVG if any
   detail fuzzes out.
