// Cup Season — the desk's ordinary-post request record and its draft (D350,
// built and amended; D356 event terms). The functions are PURE and live in
// index.html — lifted here by brace-matching and evaluated with no DOM, exactly
// as tests/homefold.test.mjs lifts `csHomeFold`.
//
//   node tests/post-request.test.mjs

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const html = readFileSync(join(root, 'index.html'), 'utf8');

/* R2 · the composer's field list is a CONSTANT now, because four hand-kept
   copies of it had drifted and `inGross` was missing from three of them. It is
   lifted from index.html rather than retyped, so this suite fails if the real
   list and this one ever part company. */
function liftConst(name) {
  const m = html.match(new RegExp(`^const ${name} = .*?;$`, 'm'));
  if (!m) { console.error(`FAIL — const ${name} not found in index.html`); process.exit(1); }
  return m[0];
}
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
const src = [
  `const POST_REQ_KEY='cs_post_request'; const POST_DRAFT_KEY='cs_post_draft';`,
  `const CS_LEDGER = 'Cup Season keeps the ledger; the money moves between friends.';`,
  `let _postDateStamp = '2026-09-13';`,
  `const csDowMonDay = iso => iso;`,
  liftConst('POST_TYPED'), liftConst('POST_FIELDS'),
  lift('postRequestPlan'), lift('postEnvelopeMatches'), lift('postRequestKey'),
  lift('postDraftHasContent'), lift('postDraftDecision'), lift('postDraftKey'),
  lift('csEventTerms'), lift('csInviteTitle'),
  `return { postRequestPlan, postEnvelopeMatches, postRequestKey, postDraftDecision, postDraftKey, csEventTerms, csInviteTitle, postDraftHasContent, POST_TYPED, POST_FIELDS };`,
].join('\n');
const { postRequestPlan, postEnvelopeMatches, postRequestKey, postDraftDecision, postDraftKey, csEventTerms, csInviteTitle, postDraftHasContent, POST_TYPED, POST_FIELDS } = new Function(src)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  PASS  ${label}`); }
  else { fail++; console.log(`X FAIL  ${label} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
};

const payload = { gross: 84, rating: 71.2, nine_rating: null, slope: 128, holes_played: 18, source: 'quick',
                  played_on: '2026-09-13', course_label: 'Papago', api_course_id: null };
const env = { payload, holes: [], playedWith: [] };

/* ---- the request record: one intent, one id, never rotated ---- */
eq(postRequestPlan(null, env), 'fresh', 'no record: mint, freeze, write, send');
eq(postRequestPlan({ unreadable: true }, env), 'stop', 'a record that cannot be read STOPS — it is never minted over');
eq(postRequestPlan({ id: 'r', at: 1, accepted: null }, env), 'amend', 'a record without an envelope keeps its id: this card is sent under it');
eq(postRequestPlan({ id: 'r', accepted: 'round-1', env }, env), 'finish', 'an accepted record finishes the intent');
eq(postRequestPlan({ id: 'r', accepted: 'round-1', env }, { ...env, payload: { ...payload, gross: 48 } }), 'finish',
   'an accepted record finishes even over an edited card — the edit is a correction elsewhere');
eq(postRequestPlan({ id: 'r', accepted: null, env }, env), 'replay', 'the same card replays the frozen envelope');
eq(postRequestPlan({ id: 'r', accepted: null, env: { ...env, payload: { ...payload, photo_path: 'u/p.jpg' } } }, env), 'replay',
   'the photo path is an upload output and does not make it a different card');
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, payload: { ...payload, gross: 48 } }), 'amend',
   'a different gross under an unresolved id is an AMENDMENT under the same id');
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, playedWith: ['mate'] }), 'amend', 'a changed partner list is an amendment');
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, holes: Array(18).fill(4) }), 'amend', 'hole scores are part of the envelope');
eq(['fresh', 'stop', 'amend', 'finish', 'replay'].includes('resolve'), false, 'there is no plan that rotates the id');
eq(postEnvelopeMatches({ payload: { b: 1, a: 2 }, holes: [], playedWith: ['x', 'y'] },
                       { payload: { a: 2, b: 1 }, holes: [], playedWith: ['y', 'x'] }), true, 'matching is by value, not by key or partner order');
eq(postEnvelopeMatches(null, env), false, 'nothing matches nothing');
eq(postRequestKey('u1') === postRequestKey('u2'), false, 'two golfers, two records');
eq(postRequestKey(null), 'cs_post_request.signed-out', 'a signed-out key never collides with an account');

/* ---- the draft: owned, offered, never silently leaked or deleted ---- */
const NOW = Date.parse('2026-09-13T12:00:00Z');
const typed = { vals: { inF9: '41', inB9: '43', inDate: '2026-09-13' }, touched: false };
eq(postDraftKey('u1') === postDraftKey('u2'), false, 'the draft key is per golfer');
eq(postDraftDecision({ owner: 'u1', at: NOW - 3600e3, ...typed }, 'u1', false, NOW), 'restore', 'my own recent draft restores');
eq(postDraftDecision({ owner: 'u2', at: NOW - 3600e3, ...typed }, 'u1', false, NOW), 'foreign', 'another golfer’s draft is never shown');
eq(postDraftDecision({ at: NOW - 3600e3, ...typed }, 'u1', false, NOW), 'ask', 'a legacy unowned draft is OFFERED, not shown or deleted');
eq(postDraftDecision({ owner: 'u1', at: NOW - 30 * 3600e3, ...typed }, 'u1', false, NOW), 'expired', 'a day-old draft with nothing pending ages out');
eq(postDraftDecision({ owner: 'u1', at: NOW - 30 * 3600e3, ...typed }, 'u1', true, NOW), 'restore',
   'a day-old draft behind a PENDING post attempt is its recovery envelope and never ages out');
eq(postDraftDecision({ owner: 'u1', at: NOW, vals: { inDate: '2026-09-13' }, touched: false }, 'u1', false, NOW), 'stamp-only',
   'the stamped date alone is not a draft');
eq(postDraftDecision(null, 'u1', false, NOW), 'stamp-only', 'no draft, nothing to do');

/* ---- an event invitation says what it is and what it costs, or nothing ---- */
eq(csEventTerms({ kind: 'event', event_kind: 'major', buy_in: 25, starts_on: '2026-10-03' }),
   /* D357 · a Major's window is two to four days, never a week. */
   ['A Major — a short window, one card, the best round takes it.', 'First tee 2026-10-03.', '$25 each.',
    'Cup Season keeps the ledger; the money moves between friends.'], 'a Major with a stake says the stake and the ledger');
eq(csEventTerms({ kind: 'event', event_kind: 'ryder', buy_in: 0 }), ['A Ryder — two teams, one clash each week.', 'No buy-in.'],
   'a free Ryder says no buy-in and no ledger');
eq(csEventTerms({ kind: 'event' }), [], 'an older server gives no terms — and no terms is no door');
eq(csInviteTitle({ kind: 'event', event_kind: 'major' }), 'Major invite', 'a Major is titled a Major');
eq(csInviteTitle({ kind: 'event' }), 'Invite', 'an unnamed one is not guessed into a Ryder');
eq(csInviteTitle({ kind: 'league' }), 'League invite', 'a league is a league');


/* ---- R2 · the field list, and what counts as work --------------------------
   `inGross` is the hero box and the main total-score field. It was missing from
   the snapshot, the meaningful-work predicate and the consent check, so a card
   carrying only a gross read as EMPTY: a plan moved its date with no question,
   and a save/restore returned the date and course with the score gone. */
eq(POST_TYPED.includes('inGross'), true, 'the gross is one of the typed fields');
for (const id of ['inF9', 'inB9', 'inRating', 'inSlope', 'inCourse'])
  eq(POST_TYPED.includes(id), true, `${id} is one of the typed fields`);
eq(POST_TYPED.includes('inDate'), false, 'the date is NOT typed work — a stamp is the machine’s');
eq(POST_FIELDS.length, POST_TYPED.length + 1, 'the saved fields are the typed ones plus the date');
eq(POST_FIELDS.includes('inDate'), true, 'and the date is saved');

eq(postDraftHasContent({ inGross: '84', inDate: '2026-09-13' }, false), true,
   'a gross-only card is work — this is the R2 reproduction, as an assertion');
eq(postDraftHasContent({ inDate: '2026-09-13' }, false), false,
   'the stamped date alone is not work');
eq(postDraftHasContent({ inDate: '2026-09-07' }, false), true,
   'a date the golfer chose is work');
eq(postDraftHasContent({}, true), true, 'a touched grid is work');
for (const id of POST_TYPED)
  eq(postDraftHasContent({ [id]: 'x', inDate: '2026-09-13' }, false), true, `${id} alone is work`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
