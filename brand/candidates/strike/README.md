# Strike (2026-09-11)

The owner narrowed The Fifty to **11** (CS with a club through it), **20** (CS on
the pennant) and **33** (the topo pennant), and asked for a bolder CS in *"your
own font that screams strike velocity, competition."*

**Strike** is that face, second cut: angular centrelines with sharp mitres so
every curve is two chamfers (weight 12 on a 40 cap), a 10° forward lean
(`skewX(-10)`), and one signature — a single slice through every mark at the
angle of a club path. The first cut was arcs and a cubic S; it read as a bold
italic, not a strike. The club is scratched (owner, 2026-09-11) for a ball in flight. A full
dimple lattice, stitching, fold lines and five contours were tried and the
owner called it "too rendered" — right. Emblem level now: ten large dimples on
the lit side and a shadow crescent, two streaks; a finial on the pole and
nothing else; three contours with an index line; the inline only on 11,
where the letters are big enough to carry it. A mark is a few decisive
lines that describe the object, never texture.

Open on 33: with the letters at the centre of the rings it tips toward a
target; the fix is to move the contours so the letters sit on a slope, not a
summit.

Letters are paths on a 40-unit grid, never a font file, so masters carry the
type and a digitiser gets geometry. Eight letters cover the name; the rest of
the alphabet follows the same four rules. `strike.svg` holds the face and the
three marks.

## preview/ (2026-09-11)

The three marks as standalone 96-grid files, knockouts as real masks so
they work on any ground: `strike-NN.svg` (gold #795912, light ground) and
`strike-NN-dark.svg` (gold #D8B25A, dark ground). `preview.html` is the
OpenDesign `svg-design` preview scaffold (tryopendata/skills, MIT), unmodified;
`variants.js` feeds it. Open `preview.html` to see each mark at 16, 32 and
64 px on both grounds, in a favicon tab and in a nav bar. Reading at size:
20 is the only one that survives 16 px as a flag; 11 is the most
distinctive from 64 up; 33's contours swallow the letters below 64.
