# DesignV1 beta production identity

Owner-approved visual reference: [`../../../Desingv1.png`](../../../Desingv1.png).
The filename is preserved exactly as supplied. This branch uses the pennant,
custom CS counters, and curved ridge as its beta production mark.

`source.json` contains clean, authored vector geometry, not raster tracing.
Run `sh tools/build-beta-mark.sh` from the repository root to generate:

- Native `CSBrandMark` geometry and the three iOS app-icon appearances.
- Light-ground, dark-ground, and one-color SVG marks.
- Horizontal CUP SEASON / ROUNDS COUNT SVG lockups with outlined lettering.
- Optically reinforced 16px and 32px icons without contour detail.

Generated outputs live in `generated/`, the native design package, and the
existing app-icon asset catalog. Edit the source/generator, not those outputs.
The lockup uses the project's bundled OFL IBM Plex Sans Condensed Bold.
No new font is introduced. Native editorial text uses the existing New York
serif because a licensed Tiempos Headline font is not present.

The source remains isolated here so the beta selection is reversible. The
older candidate files and historical decision records remain intact.
