# Continuous topo visual review · d837a8c0

- Native Scoreboard, dark and light: contour strokes continue under the eyebrow, title, story, points, rule and standing. There is no internal strip boundary or extra reserved strip height. Clipping is at the outer panel edge.
- Native standard/SE: the same width-based geometry keeps its shape; text stays full-strength. At AX3 the taller panel carries the contours behind wrapped text and continues to scroll normally. The Book heading places its title over the same contour family.
- Web dark/light Scoreboard: inherited SVG translation, stacking and color are explicitly resolved so the field covers the full panel. The season head uses the same class. The Book header uses that geometry too; the 375-point browser check keeps the heading and close control legible and separate.
- Contrast measurements and all four Book UI tests pass. No scoring or navigation changes were introduced. The 36 simulator captures and four browser captures are refreshed; the earlier selected gallery is retained separately for comparison.
