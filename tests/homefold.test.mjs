// Cup Season — the desk's fold (D288). The phone's `HomeFeedFold` has
// `HomeFeedFoldTests.swift` behind it; the desk's twin had nothing behind it,
// which is how `renderHomeFeed` came to filter on a column two selects did not
// carry and nobody noticed for four waves.
//
// `csHomeFold` and `csNotesLine` are PURE functions in index.html (classic
// block) — extracted here by brace-matching and evaluated with no DOM, exactly
// as tests/sunningdale.test.mjs extracts `sunnEngine`.
//
//   node tests/homefold.test.mjs

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
const { csHomeFold, csNotesLine } =
  new Function(`${lift('csHomeFold')}\n${lift('csNotesLine')}\nreturn { csHomeFold, csNotesLine };`)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  PASS  ${label}`); }
  else { fail++; console.log(`X FAIL  ${label} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
};

const TODAY = '2026-09-07';
const L1 = 'league-fellas', L2 = 'league-bitch', L3 = 'league-third';
const NAMES = { [L1]: 'Fellas', [L2]: "Who's the bitch?", [L3]: 'The Third' };
const nameOf = id => NAMES[id] || null;
const fold = (o = {}) => csHomeFold({ today: TODAY, leagueName: nameOf, ...o });
const post = (o) => ({ id: o.id, league_id: o.lg, kind: o.kind || 'system', body: o.body,
                       created_at: o.at, round_id: o.rid || null, live_round_id: o.lrid || null });
const round = (o) => ({ r: { round_id: o.rid, gross: o.gross ?? 84, played_on: o.on },
                        i: o.i ?? 0, t: o.at || (o.on + 'T12:00:00Z'), d: o.on });
const rows = f => f.buckets.map(b => [b.key, b.items.length]);

/* ── 1 · one round, one row ──────────────────────────────────────────────── */
{
  // `round_to_board()` fans one round into every league the golfer is in.
  // Two leagues → two identical posts → ONE line carrying both names.
  const f = fold({ posts: [
    post({ id: 'a', lg: L1, kind: 'moment', body: 'Jerecho set a personal best.', at: '2026-09-07T15:00:00Z', rid: 'R1' }),
    post({ id: 'b', lg: L2, kind: 'moment', body: 'Jerecho set a personal best.', at: '2026-09-07T15:00:00Z', rid: 'R1' }),
  ] });
  eq(f.buckets[0].items.length, 1, 'a moment fanned to two leagues is one moment');
  eq(f.buckets[0].items[0].leagues.map(s => s.name), ['Fellas', "Who's the bitch?"],
     'and the survivor carries BOTH league names');
}
{
  // Two DIFFERENT rounds are two moments, however alike the sentence.
  const f = fold({ posts: [
    post({ id: 'a', lg: L1, kind: 'moment', body: 'Broke 80.', at: '2026-09-07T15:00:00Z', rid: 'R1' }),
    post({ id: 'b', lg: L1, kind: 'moment', body: 'Broke 80.', at: '2026-09-07T15:00:00Z', rid: 'R2' }),
  ] });
  eq(f.buckets[0].items.length, 2, 'two rounds are two moments, alike or not');
}
{
  // No round to key on: the body, inside the same 48-hour window.
  const near = fold({ posts: [
    post({ id: 'a', lg: L1, kind: 'moment', body: 'August is in the books.', at: '2026-09-07T09:00:00Z' }),
    post({ id: 'b', lg: L2, kind: 'moment', body: 'august is in the books.', at: '2026-09-07T09:01:00Z' }),
  ] });
  eq(near.buckets[0].items.length, 1, 'a round-less moment folds on its body inside 48h');
  const far = fold({ posts: [
    post({ id: 'a', lg: L1, kind: 'moment', body: 'August is in the books.', at: '2026-09-07T09:00:00Z' }),
    post({ id: 'b', lg: L2, kind: 'moment', body: 'August is in the books.', at: '2026-09-01T09:00:00Z' }),
  ] });
  eq(far.buckets.reduce((n, b) => n + b.items.length, 0), 2, 'and does NOT fold outside it');
}

/* ── 2 · the deck already told it (F-2) ──────────────────────────────────── */
{
  const f = fold({
    rounds: [round({ rid: 'R1', on: '2026-09-07', i: 0 }), round({ rid: 'R2', on: '2026-09-07', i: 1 })],
    posts: [post({ id: 'a', lg: L1, kind: 'moment', body: 'A best.', at: '2026-09-07T15:00:00Z', rid: 'R1' })],
    spent: new Set(['R1']) });
  eq(f.buckets[0].items.length, 1, 'a spent round is dropped, and so is the post about it');
  eq(f.buckets[0].items[0].r.round_id, 'R2', 'the unspent round survives');
}

/* ── 3 · the league notes are a LINE, not rows ───────────────────────────── */
{
  // The owner's photograph: the clash lines, once per league.
  const f = fold({ posts: [
    post({ id: 'a', lg: L1, body: 'The clash closes today.', at: '2026-09-07T06:00:00Z' }),
    post({ id: 'b', lg: L2, body: 'The clash closes today.', at: '2026-09-07T06:00:00Z' }),
    post({ id: 'c', lg: L1, body: 'THIS WEEK: Galen v Jerecho.', at: '2026-09-06T06:00:00Z' }),
    post({ id: 'd', lg: L2, body: 'THIS WEEK: Galen v Jerecho.', at: '2026-09-06T06:00:00Z' }),
  ] });
  eq(f.buckets.length, 0, 'a league note is never a row');
  eq(f.notes.count, 2, 'four notes across two leagues count as the two notes they are');
  eq(csNotesLine(f.notes), "Fellas & Who's the bitch? · 2 league notes", 'and print as one line');
  eq(f.notes.leagueId, L1, 'the line opens the newest note’s board');
}
{
  eq(csNotesLine({ names: ['Fellas'], count: 1 }), 'Fellas · 1 league note', 'one league, one note — singular');
  eq(csNotesLine({ names: ['A', 'B', 'C'], count: 14 }), '3 leagues · 14 league notes',
     'past two leagues the names become a count');
  eq(csNotesLine({ names: [], count: 3 }), 'Your leagues · 3 league notes', 'and a nameless league still reads');
}

/* ── 4 · the four datelines ──────────────────────────────────────────────── */
{
  const f = fold({ rounds: [
    round({ rid: 'A', on: '2026-09-10', i: 0 }),   // ahead
    round({ rid: 'B', on: '2026-09-07', i: 1 }),   // today
    round({ rid: 'C', on: '2026-09-03', i: 2 }),   // this week
    round({ rid: 'D', on: '2026-08-20', i: 3 }),   // earlier
  ] });
  eq(rows(f), [['ahead', 1], ['today', 1], ['week', 1], ['earlier', 1]], 'four buckets, in the wire’s order');
  eq(f.buckets.map(b => b.label), ['Coming up', 'Today', 'This week', 'Earlier'], 'and their datelines');
  eq(fold({ rounds: [round({ rid: 'E', on: '2026-09-01', i: 0 })] }).buckets[0].key, 'week',
     'six days back is still this week');
  eq(fold({ rounds: [round({ rid: 'F', on: '2026-08-31', i: 0 })] }).buckets[0].key, 'earlier',
     'seven is earlier');
}

/* ── 5 · a rundown says a date once ──────────────────────────────────────── */
{
  const f = fold({ rounds: [
    round({ rid: 'A', on: '2026-09-07', i: 0, at: '2026-09-07T18:00:00Z' }),
    round({ rid: 'B', on: '2026-09-07', i: 1, at: '2026-09-07T12:00:00Z' }),
    round({ rid: 'C', on: '2026-09-05', i: 2, at: '2026-09-05T12:00:00Z' }),
    round({ rid: 'D', on: '2026-09-05', i: 3, at: '2026-09-05T11:00:00Z' }),
    round({ rid: 'E', on: '2026-09-04', i: 4, at: '2026-09-04T11:00:00Z' }),
  ] });
  eq(f.buckets[0].items.map(x => x.stamp), [null, null], 'a row under TODAY never says Today');
  eq(f.buckets[1].items.map(x => x.stamp), ['2026-09-05', null, '2026-09-04'],
     'inside a group, only the first of a run carries the date');
}

/* ── 6 · the order, and the empty ────────────────────────────────────────── */
{
  const f = fold({ rounds: [
    round({ rid: 'A', on: '2026-09-05', i: 0, at: '2026-09-05T09:00:00Z' }),
    round({ rid: 'B', on: '2026-09-06', i: 1, at: '2026-09-06T09:00:00Z' }),
  ] });
  eq(f.buckets[0].items.map(x => x.r.round_id), ['B', 'A'], 'newest first inside a bucket');
  eq(f.buckets[0].items.map(x => x.i), [1, 0], 'and the source index rides along for the reaction strip');
}
{
  const f = fold({});
  eq([f.buckets.length, f.notes], [0, null], 'nothing in, nothing out — and no crash');
  const undated = fold({ posts: [post({ id: 'a', lg: L1, kind: 'moment', body: 'No stamp.', at: null })] });
  eq(undated.buckets[0].key, 'earlier', 'an undated row files under earlier');
  eq(undated.buckets[0].items[0].stamp, null, 'and prints no stamp it cannot vouch for');
}

console.log(`\n${fail === 0 ? 'PASS' : 'FAIL'} — ${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
