// Cup Season — Sunningdale engine tests (D74). TDD: this file was written RED,
// against an engine that did not exist, and every case failed before the
// implementation was written. Run: node tests/sunningdale.test.mjs
//
// sunnEngine is a PURE function in index.html (classic block) — extracted here
// by brace-matching and evaluated with no DOM, exactly as preflight does its
// source checks. Contract:
//   sunnEngine({ scores, teams, holes })
//     scores : per-player 18-wide arrays of gross (null = unplayed)
//     teams  : [[playerIdx...],[playerIdx...]]  (1v1 or 2v2)
//     holes  : 9 | 18
//   → { a, b, played, closed, bank, strokes }
//     a/b     : holes won per side
//     closed  : null | {winner:0|1, lead, rem}
//     bank    : SIGNED units (+N = side A holds N, −N = side B)
//     strokes : [sA, sB] for the UPCOMING hole (deficit−1, floor 0)

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const html = readFileSync(join(root, 'index.html'), 'utf8');

const at = html.indexOf('function sunnEngine(');
if (at < 0) {
  console.error('FAIL — sunnEngine not found in index.html (engine not implemented)');
  process.exit(1);
}
// brace-match the function body
let i = html.indexOf('{', at), depth = 0, end = -1;
for (; i < html.length; i++) {
  if (html[i] === '{') depth++;
  else if (html[i] === '}') { depth--; if (depth === 0) { end = i + 1; break; } }
}
const src = html.slice(at, end);
const sunnEngine = new Function(`${src}; return sunnEngine;`)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const g = JSON.stringify(got), w = JSON.stringify(want);
  if (g === w) { pass++; }
  else { fail++; console.error(`FAIL ${label}\n  want ${w}\n  got  ${g}`); }
};

// helpers: build 18-wide score arrays
const S = (...vals) => { const a = Array(18).fill(null); vals.forEach((v, k) => { a[k] = v; }); return a; };
const singles = (sa, sb, holes = 18) => sunnEngine({ scores: [sa, sb], teams: [[0], [1]], holes });

// 1 · straight up: A birdies h1, halves h2 — one hole won, no strokes, bank +1
{
  const r = singles(S(3, 4), S(4, 4));
  eq([r.a, r.b, r.played], [1, 0, 2], 't1 wins/played');
  eq(r.strokes, [0, 0], 't1 no strokes at 1 up');
  eq(r.bank, 1, 't1 first win while ahead banks a unit');
  eq(r.closed, null, 't1 open');
}

// 2 · the core rule: 2 down entering a hole = 1 stroke ON that hole.
//     B loses h1,h2 straight; h3 both gross 4 — B's stroke wins it net.
{
  const r = singles(S(3, 3, 4), S(4, 4, 4));
  eq([r.a, r.b, r.played], [2, 1, 3], 't2 stroke wins the hole for the 2-down side');
  eq(r.strokes, [0, 0], 't2 back to 1 down — strokes gone');
}

// 3 · scaling: 3 down entering → 2 strokes; 4 down → 3.
//    (The red run caught the original data here: with identical grosses the
//    deficit stroke HALVES h3 — you cannot go 3 down without losing THROUGH
//    the stroke. The equalizer working is the point of the game.)
{
  const r3 = singles(S(3, 3, 3), S(4, 4, 5));         // h3: B 5−1=4 loses through the stroke
  eq(r3.strokes, [0, 2], 't3 three down → two strokes next');
  const r4 = singles(S(3, 3, 3, 3), S(4, 4, 5, 6));   // h4: B 6−2=4 loses through two strokes → 4 down
  eq(r4.strokes, [0, 3], 't3 four down → three strokes next');
}

// 4 · the stroke persists while 2+ down (not one-time): B halves h3 net, still 2 down → stroke again on h4
{
  const r = singles(S(3, 3, 4, 4), S(4, 4, 5, 4));   // h3: B 5−1=4 halved; h4: B 4−1=3 wins
  eq([r.a, r.b], [2, 1], 't4 stroke available again the following hole');
}

// 5 · teams, net best ball: BOTH trailing players get the stroke
{
  const r = sunnEngine({
    scores: [S(4, 4, 4), S(4, 4, 5), S(5, 5, 5), S(5, 5, 5)],
    teams: [[0, 1], [2, 3]], holes: 18,
  });
  // A best ball 4,4 wins h1,h2; h3: C/D each 5−1=4 vs A best 4 — halved
  eq([r.a, r.b, r.played], [2, 0, 3], 't5 team strokes make the halve');
}

// 6 · closeout respects the hole count (D73): 5 up after 5 on a NINE = 5&4.
//    B must lose THROUGH the growing strokes (gross = 3 + strokes + 1).
{
  const B5 = S(4, 4, 5, 6, 7);
  const r = singles(S(3, 3, 3, 3, 3), B5, 9);
  eq(r.closed, { winner: 0, lead: 5, rem: 4 }, 't6 closes on nine');
}
// …the same five holes stay open on 18 (13 remain)
{
  const r = singles(S(3, 3, 3, 3, 3), S(4, 4, 5, 6, 7), 18);
  eq(r.closed, null, 't7 open on eighteen');
}
// 8 · an 18-hole runaway still closes: ten straight (through the strokes) = 10&8
{
  const A = S(...Array(10).fill(3));
  const B = S(4, 4, 5, 6, 7, 8, 9, 10, 11, 12);   // deficit strokes 0,0,1,2,… — always net 4
  const r = singles(A, B, 18);
  eq(r.closed, { winner: 0, lead: 10, rem: 8 }, 't8 18-hole closeout');
}

// 9 · the bank, full article sequence (strokes interleaved):
//    A wins h1 (+1), h2 (+2). B then wins five straight:
//    h3 (2dn, stroke, →1dn: no bank) · h4 (→square: no bank) ·
//    h5 (→B 1up: +1 toward B = 1) · h6 (→B 2up: bank 0) · h7 (→B 3up: B banks, −1)
{
  const a = S(3, 3, 4, 5, 5, 5, 6);   // h7: A gross 6 loses through A's own comeback stroke (6−1=5 vs 4)
  const b = S(4, 4, 4, 4, 4, 4, 4);   // h3: B's stroke wins it (4−1=3 beats 4); h4+ straight up
  const r = singles(a, b);
  eq([r.a, r.b], [2, 5], 't9 wins tally');
  eq(r.bank, -1, 't9 bank walks +2 → −1 exactly one unit per qualifying win');
  eq(r.strokes, [2, 0], 't9 A now 3 down → two strokes coming');
}

// 10 · halved holes move nothing
{
  const r = singles(S(4, 4, 4), S(4, 4, 4));
  eq([r.a, r.b, r.played, r.bank], [0, 0, 3, 0], 't10 all square, empty bank');
}

// 11 · incomplete hole stops the count (co-scoring mid-hole)
{
  const a = S(4, 4); a[2] = 4;             // A has h3
  const b = S(5, 5);                        // B doesn't
  const r = singles(a, b);
  eq(r.played, 2, 't11 stops at first incomplete hole');
}

/* ===================== D75 · solo Sunningdale (everyone for themselves) =====
   sunnSoloEngine({scores, holes}) — own ball, outright low net wins the hole
   (ties halve to nobody). Entering a hole each player gets
   max(0, gapToLeader−1) strokes. Bank: single-owner walk — a qualifying win
   (outright leader AFTER winning) grows your bank or pulls one unit from the
   holder. Returns {wins, played, strokes(next), bank:{owner,units}}. */
const at2 = html.indexOf('function sunnSoloEngine(');
if (at2 < 0) {
  console.error('FAIL — sunnSoloEngine not found in index.html (solo engine not implemented)');
  process.exit(1);
}
let i2 = html.indexOf('{', at2), d2 = 0, end2 = -1;
for (; i2 < html.length; i2++) {
  if (html[i2] === '{') d2++;
  else if (html[i2] === '}') { d2--; if (d2 === 0) { end2 = i2 + 1; break; } }
}
const sunnSoloEngine = new Function(`${html.slice(at2, end2)}; return sunnSoloEngine;`)();

const solo = (scoreRows, holes = 18) => sunnSoloEngine({ scores: scoreRows.map(r => S(...r)), holes });

// s1 · outright low wins; ties halve to nobody
{
  const r = solo([[3,4],[4,4],[4,4],[5,4]]);
  eq(r.wins, [1,0,0,0], 's1 outright low takes h1; tied h2 goes to nobody');
  eq(r.played, 2, 's1 played');
}
// s2 · deficit strokes vs the leader: A wins 3 straight; entering h4 the field
//      is 3 back → everyone else gets 2 strokes
{
  /* the field must LOSE h3 through their stroke (gross 5, net 4 vs A's 3) —
     flat grosses would tie it, which is the equalizer working */
  const r = solo([[3,3,3],[4,4,5],[4,4,5],[4,4,5]]);
  eq(r.strokes, [0,2,2,2], 's2 three back → two strokes each');
}
// s3 · the stroke changes a hole: B (2 back entering h3) nets 4−1=3 vs A's 4 — B wins it
{
  const r = solo([[3,3,4,4],[4,4,4,4],[5,5,5,5],[5,5,5,5]]);
  eq(r.wins.slice(0,2), [2,1], 's3 the equalizer stroke wins the hole outright');
}
// s4 · bank walk, single owner: A banks 2 (wins h1,h2 leading outright);
//      B's comeback win while still behind banks nothing; B's win that makes
//      B the outright leader pulls a unit out of A's bank
{
  /* C/D at gross 7 so their deficit strokes never tie B's wins away —
     flat 5s let the equalizer halve the holes (caught red) */
  const rows=[[3,3,5,5,5,5],[4,4,4,4,4,4],[7,7,7,7,7,7],[7,7,7,7,7,7]];
  // h1,h2: A wins (bank A2). h3: B 2 back → 1 stroke → net 3 outright (A2 B1, A still outright: no pull).
  // h4: B wins straight (A2 B2 tied — nobody outright → no move).
  // h5: B wins (B3 — outright → pulls one: A bank 2→1).
  // h6: B wins (B4 — pull: A bank 1→0).
  const r = solo(rows);
  eq(r.wins, [2,4,0,0], 's4 wins tally');
  eq(r.bank, { owner:0, units:0 }, 's4 the walk: A banked 2, B pulled both back out');
}
// s5 · after emptying the holder, further qualifying wins bank for the NEW leader
{
  const rows=[[3,3,5,5,5,5,6],[4,4,4,4,4,4,4],[7,7,7,7,7,7,8],[7,7,7,7,7,7,8]];
  const r = solo(rows);   // h7: B wins again (B5) — bank empty → B banks 1
  eq(r.bank, { owner:1, units:1 }, 's5 bank flips to the new leader');
}
// s6 · 9-hole aware: stops at the hole count
{
  const rows=[[3,3,3,3,3,3,3,3,3,3],[4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4],[4,4,4,4,4,4,4,4,4,4]];
  const r = solo(rows, 9);
  eq(r.played, 9, 's6 a nine ends at nine');
}
// s7 · incomplete hole stops the count
{
  const rows=[[3,3],[4,4],[4,4],[4,null]];
  const r = solo(rows.map(x=>x));
  eq(r.played, 1, 's7 stops when any card is open');
}

console.log(fail === 0 ? `PASS — ${pass} assertions` : `${fail} FAILED · ${pass} passed`);
process.exit(fail === 0 ? 0 : 1);
