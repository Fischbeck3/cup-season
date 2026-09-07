// Cup Season — the case's three shelves and the BESTS sub-line (D291).
//
// The phone's half is compiled and unit-tested (`TrophyMeta.shelf`,
// `TrophyMeta.milestoneSub`, `TrophyCase.shelves`); the desk's half is four
// functions inside a template string in `index.html`, which is exactly the
// kind of twin that drifts silently. D234 says the shelf rule and the
// produced sentence are ONE producer in two shapes — this file is the only
// thing that can say so about the shape that has no compiler.
//
// `csTrophyShelf`, `csMonthDay`, `csMilestoneSub` and `achSubtitle` are pure
// functions in index.html's classic block — lifted here by brace-matching and
// evaluated with no DOM, exactly as tests/rating.test.mjs does.
//
//   node tests/trophycase.test.mjs

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
function liftConst(name) {
  const re = new RegExp(`^const ${name} = [\\s\\S]*?;$`, 'm');
  const m = re.exec(html);
  if (!m) { console.error(`FAIL — const ${name} not found`); process.exit(1); }
  return m[0];
}

const MOS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const env = new Function(`
  const MOS = ${JSON.stringify(MOS)};
  const localDate = iso => { const p = String(iso).split('-').map(Number);
    return p.length === 3 ? new Date(p[0], p[1] - 1, p[2]) : new Date(NaN); };
  const csCourse = s => String(s);
  const window = { career: { rows: [] } };
  ${liftConst('CS_BESTS')}
  ${liftConst('CS_SHELF')}
  ${liftConst('CS_CASE_EMPTY')}
  ${lift('csTrophyShelf')}
  ${lift('csMonthDay')}
  ${lift('csMilestoneRound')}
  ${lift('achSubtitle')}
  ${lift('csMilestoneSub')}
  return { csTrophyShelf, csMonthDay, csMilestoneSub, csMilestoneRound, CS_SHELF, CS_BESTS, CS_CASE_EMPTY, window };
`)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  PASS  ${label}`); }
  else { fail++; console.log(`X FAIL  ${label} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
};
const ok = (cond, label) => eq(!!cond, true, label);

/* ── 1 · the shelf rule, verbatim with `TrophyMeta.shelf` ───────────────── */
{
  const { csTrophyShelf } = env;
  eq(csTrophyShelf('league', true), 'hardware', 'every trophy row is hardware');
  eq(csTrophyShelf('ryder', true), 'hardware', 'the Ryder is hardware');
  // an achievement kind is never hardware even when its glyph is a cup
  eq(csTrophyShelf('league', false), 'along', 'a non-trophy kind is never hardware');
  for (const k of ['sub_100', 'sub_90', 'sub_80', 'personal_best', 'low_round', 'most_improved'])
    eq(csTrophyShelf(k, false), 'bests', `${k} is a best`);
  for (const k of ['first_round', 'streak_4', 'streak_8', 'streak_12'])
    eq(csTrophyShelf(k, false), 'along', `${k} is along the way`);
  // AN UNKNOWN KIND IS QUIET, NEVER LOUD. A migration that mints something
  // this build has never heard of must not put it above the Cup.
  eq(csTrophyShelf('grand_slam_2031', false), 'along', 'an unknown kind falls to the quiet shelf');
  eq(csTrophyShelf(null, false), 'along', 'a null kind falls to the quiet shelf');
}

/* ── 2 · three sizes, and the size is the whole of the hierarchy ────────── */
{
  const { CS_SHELF } = env;
  eq(CS_SHELF.hardware.mark, 44, 'hardware draws at 44pt');
  eq(CS_SHELF.bests.mark, 28, 'a best draws at 28pt');
  eq(CS_SHELF.along.mark, 28, 'the quiet shelf draws at 28pt');
  ok(CS_SHELF.hardware.mark > CS_SHELF.bests.mark, 'a Cup outranks a broken 80');
  eq([CS_SHELF.hardware.head, CS_SHELF.bests.head, CS_SHELF.along.head],
     ['Hardware', 'Bests', 'Along the way'], 'the three heads');
}

/* ── 3 · "Aug 24", by the local constructor ─────────────────────────────── */
{
  const { csMonthDay } = env;
  eq(csMonthDay('2026-08-24'), 'Aug 24', 'a date is a month and a day');
  // CLAUDE.md: `new Date('YYYY-MM-DD')` is UTC midnight and renders the day
  // BEFORE in Phoenix. The first of a month is where that shows.
  eq(csMonthDay('2026-09-01'), 'Sep 1', 'the first of the month is not the last of the one before');
  eq(csMonthDay('2026-08-24T00:00:00Z'), 'Aug 24', 'a timestamp is cut to its date');
  eq(csMonthDay(''), '', 'nothing produces nothing');
  eq(csMonthDay(null), '', 'a null date produces nothing');
  eq(csMonthDay('not a date'), '', 'an unparseable date produces nothing, never NaN');
}

/* ── 4 · a BESTS slat says the round it was won on ──────────────────────── */
{
  const { csMilestoneSub } = env;
  const a = { kind: 'sub_80', label: 'Broke 80', earned_on: '2026-08-24', meta: { gross: 79 } };

  eq(csMilestoneSub(a, { gross: 79, course_label: 'Papago', played_on: '2026-08-24' }),
     '79 at Papago · Aug 24', 'the round in hand names its course');

  // THE DEGRADE IS THE POINT. The desk holds 400 rounds and the phone holds
  // five; a milestone older than that window keeps its figure and its date
  // and invents no course (L-44).
  eq(csMilestoneSub(a, null), '79 · Aug 24', 'no round in hand keeps the figure and the date');
  // NEVER the label: the slat's own title already reads BROKE 80, and
  // "Broke 80 · Aug 24" beneath it is the name twice.
  eq(csMilestoneSub({ ...a, meta: {} }, null), 'Aug 24', 'no figure anywhere leaves the date alone');
  eq(csMilestoneSub({ ...a, meta: {}, earned_on: null }, null), '', 'no figure and no date is nothing at all');
  eq(csMilestoneSub({ ...a, earned_on: null }, null), '79', 'no date at all is the figure alone');

  // the round WINS over the meta — the meta's gross is a snapshot, the round
  // is the row, and where they disagree the row is the fact.
  eq(csMilestoneSub(a, { gross: 78, course_label: null, played_on: '2026-08-20' }),
     '78 · Aug 20', 'the round outranks the snapshot');

  // a personal best carries a DIFFERENTIAL, not a gross — D210's words survive
  const pb = { kind: 'personal_best', label: 'Personal best', earned_on: '2026-08-24', meta: { diff: 4.1 } };
  eq(csMilestoneSub(pb, null), '4.1 vs course · Aug 24', 'a personal best keeps the house name for its figure');
  // A MILESTONE PRINTS THE FIGURE IT IS ABOUT. Taking the round's GROSS here
  // put the identical sentence under BROKE 80 and PERSONAL BEST whenever one
  // round earned them together — the owner's own complaint, arriving inside
  // the fix for it. The personal best keeps its differential and gains the
  // course; the threshold keeps its gross.
  eq(csMilestoneSub(pb, { gross: 79, course_label: 'Papago', played_on: '2026-08-24' }),
     '4.1 vs course · Papago · Aug 24', 'a personal best never borrows the threshold\'s sentence');
  eq(csMilestoneSub(a, { gross: 79, course_label: 'Papago', played_on: '2026-08-24' }),
     '79 at Papago · Aug 24', 'and the two never read the same on one round');
}

/* ── 5 · the lookup is absent, never wrong ──────────────────────────────── */
{
  const { csMilestoneRound, window: w } = env;
  eq(csMilestoneRound(null), null, 'no round id, no round');
  eq(csMilestoneRound('r1'), null, 'an id with nothing behind it is null, not undefined');
  w.career.rows = [{ id: 'r1', gross: 79, course_label: 'Papago', played_on: '2026-08-24' }];
  eq(csMilestoneRound('r1').gross, 79, 'the id finds its round');
  // ids come back from the server as strings and live in memory as strings,
  // but a uuid compared loosely is a class of bug worth one assertion
  eq(csMilestoneRound({ toString: () => 'r1' }).gross, 79, 'the id is compared as a string');
}

/* ── 6 · the empty is four REAL marks, never four placeholders ──────────── */
{
  const { CS_CASE_EMPTY } = env;
  eq(CS_CASE_EMPTY.marks.length, 4, 'four marks');
  eq(CS_CASE_EMPTY.marks.map(m => m[0]), ['cup', 'threshold', 'personalBest', 'crown'],
     'and each one is a mark the case really draws');
  eq(CS_CASE_EMPTY.marks[1][1], '80', 'the threshold carries its numeral, so it is a mark and not a shape');
  ok(!/⊕|★|✦/.test(CS_CASE_EMPTY.lead + CS_CASE_EMPTY.head), 'no dingbat in the empty (§5.2)');
}

/* ── 7 · the two kinds nothing can mint are still MAPPED ────────────────── */
{
  // D291's honest half: `low_round` and `most_improved` have no producer
  // anywhere in the database. They are KEPT rather than deleted, because a
  // mapping deleted today is a real trophy drawn as a `medal` the day a
  // producer lands. This asserts the decision, so a later sweep has to argue
  // with a test rather than with a comment.
  ok(/low_round:\s*\{glyph:'lowRound'/.test(html), 'low_round keeps its mark');
  ok(/most_improved:\s*\{glyph:'improved'/.test(html), 'most_improved keeps its mark');
  const { csTrophyShelf } = env;
  eq(csTrophyShelf('low_round', false), 'bests', 'and both would land on BESTS the day one fires');
  eq(csTrophyShelf('most_improved', false), 'bests', 'most improved is a scoring award, not a participation one');
}

/* ── 8 · no two marks in ACH_META are the same mark (§5.2) ──────────────── */
{
  const meta = new Function(`${liftConst('ACH_META')} return ACH_META;`)();
  const keys = Object.values(meta).map(m => m.glyph + '|' + (m.numeral || ''));
  eq(new Set(keys).size, keys.length, 'no two achievements share a glyph');
  eq(Object.keys(meta).length, 10, 'ten kinds are mapped');
}

/* ── 9 · the door is the middle shelf's, and only its ──────────────────── */
{
  // Three shelves have to read as three RANKS. Hardware takes the 44pt mark
  // and its year; a BEST takes the door into the round it was won on; the
  // quiet shelf takes neither, and this asserts the renderer nulls the id
  // rather than relying on the CSS to hide a chevron it still drew.
  const src = html.slice(html.indexOf('function renderTrophyCase'),
                         html.indexOf('window.renderCareerRecord'));
  ok(/const rid = shelf==='bests' \? \(a\.round_id\|\|null\) : null;/.test(src),
     'only a BESTS slat carries a round id into the cell');
  ok(/data-achr="\$\{esc\(o\.rid\)\}"/.test(src), 'and the door is that id');
}

console.log(fail ? `\nFAIL — ${pass} passed, ${fail} failed` : `\nPASS — ${pass} passed, 0 failed`);
process.exit(fail ? 1 : 0);
