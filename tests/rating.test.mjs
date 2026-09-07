// Cup Season — the desk's rating rail (D289). The phone's `CSStarRail` has
// `StarRailTests` behind it; the desk's twin is a CSS `calc()` string built in
// JavaScript, which is exactly the kind of arithmetic that drifts silently —
// a half star drawn at 47% of the rail rather than at the star's own midpoint
// is a control that lies by two pixels and nobody writes a bug report.
//
// `csStarsWidth` and `csStarsSvg` are pure functions in index.html (classic
// block) — extracted here by brace-matching and evaluated with no DOM, exactly
// as tests/homefold.test.mjs and tests/sunningdale.test.mjs do.
//
//   node tests/rating.test.mjs

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const html = readFileSync(join(root, 'index.html'), 'utf8');

function lift(name) {
  const at = html.indexOf(`function ${name}(`);
  if (at < 0) { console.error(`FAIL — ${name} not found in index.html`); process.exit(1); }
  let i = html.indexOf('{', at), depth = 0, end = -1;
  for (; i < html.length; i++) {
    if (html[i] === '{') depth++;
    else if (html[i] === '}') { depth--; if (depth === 0) { end = i + 1; break; } }
  }
  return html.slice(at, end);
}
const PATH = /const CS_STAR_PATH = '[^']+';/.exec(html);
if (!PATH) { console.error('FAIL — CS_STAR_PATH not found'); process.exit(1); }

const { csStarsWidth, csStarsSvg } = new Function(
  `const esc = s => String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;');`
  + `\n${PATH[0]}\n${lift('csStarsWidth')}\n${lift('csStarsSvg')}`
  + `\nreturn { csStarsWidth, csStarsSvg };`)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  PASS  ${label}`); }
  else { fail++; console.log(`X FAIL  ${label} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
};
const ok = (cond, label) => eq(!!cond, true, label);

/* ── 1 · the fill window is the VALUE, in the rail's own geometry ───────── */
{
  // A rail is five stars with `--s1` between them, so a whole star is
  // `--star + --s1` of travel and a half is half a STAR — never half of
  // `(star + gap)`, and never a percentage of the whole rail, both of which
  // land the half-star edge inside the gap instead of on the glyph.
  eq(csStarsWidth(0), 'calc(0 * (var(--star) + var(--s1)) + 0 * var(--star))',
     'zero fills nothing');
  eq(csStarsWidth(5), 'calc(5 * (var(--star) + var(--s1)) + 0 * var(--star))',
     'five fills five whole stars and no gap after the last');
  eq(csStarsWidth(4.5), 'calc(4 * (var(--star) + var(--s1)) + 0.5 * var(--star))',
     'four and a half is four whole steps plus half a GLYPH');
  eq(csStarsWidth(0.5), 'calc(0 * (var(--star) + var(--s1)) + 0.5 * var(--star))',
     'half a star is half the first glyph');
}

/* ── 2 · out of range is clamped, not drawn ─────────────────────────────── */
{
  // `course_ratings` constrains 0.5…5.0 and the RPC refuses anything else, so
  // a rail asked to draw 7 is a bug upstream — it clamps rather than drawing
  // seven stars' worth of fill over five.
  eq(csStarsWidth(9), csStarsWidth(5), 'above five clamps to five');
  eq(csStarsWidth(-2), csStarsWidth(0), 'below zero clamps to zero');
  eq(csStarsWidth(undefined), csStarsWidth(0), 'nothing clamps to zero');
}

/* ── 3 · a picture is aria-hidden; a control is not ─────────────────────── */
{
  const pic = csStarsSvg(4, false, { size: 22 });
  ok(pic.includes('aria-hidden="true"'), 'a rail with no `rate` is a picture and is hidden from the reader');
  ok(!pic.includes('<button'), 'and it carries no target at all');

  const ctl = csStarsSvg(4, false, { size: 48, rate: 'course-1' });
  ok(!ctl.includes('aria-hidden="true"'), 'a rail with `rate` is a control and is NOT hidden');
  eq((ctl.match(/<button/g) || []).length, 10, 'ten half-star targets, one per half');
  ok(ctl.includes('data-csval="0.5"') && ctl.includes('data-csval="5"'),
     'the first target is half a star and the last is five — a rail cannot be dragged to zero');
  ok(ctl.includes('aria-label="0.5 stars"') && ctl.includes('aria-label="1 star"'),
     'and each target says its own value, singular at one');
}

/* ── 4 · the unrated rail is FULL SIZE, and only its outline changes ────── */
{
  // §9.11 · a shrunken control is how "nobody has rated this" becomes
  // indistinguishable from "there is nothing here".
  const un = csStarsSvg(0, true, { size: 48, rate: 'c' });
  const on = csStarsSvg(0, false, { size: 48, rate: 'c' });
  ok(un.includes('--star:48px') && on.includes('--star:48px'), 'both draw at the same size');
  ok(un.includes('var(--mut)') && on.includes('var(--rule)'), 'and only the outline tone differs');
  ok(un.includes('is-unrated'), 'the unrated rail says so in a class, not in a size');
}

/* ── 5 · no gold, in any state ──────────────────────────────────────────── */
{
  // D289 / §2.4 · an average of opinions is not earned, and gold may never
  // touch a control (LINT-11). This is the desk's half of that rule, checked
  // rather than trusted.
  for (const v of [0, 0.5, 2.5, 4.5, 5]) {
    ok(!csStarsSvg(v, false, { size: 48, rate: 'c' }).includes('--gold'),
       `no gold on the rail at ${v}`);
  }
}

console.log(fail ? `\nFAIL — ${pass} passed, ${fail} failed` : `\nPASS — ${pass} passed, 0 failed`);
process.exit(fail ? 1 : 0);
