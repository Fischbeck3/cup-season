// Cup Season — the desk's ordinary-post request record (D350, built).
// `postRequestPlan` and `postEnvelopeMatches` are PURE functions in index.html
// (classic block) — lifted here by brace-matching and evaluated with no DOM,
// exactly as tests/homefold.test.mjs lifts `csHomeFold`.
//
//   node tests/post-request.test.mjs

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
const { postRequestPlan, postEnvelopeMatches, postRequestKey } =
  new Function(`const POST_REQ_KEY='cs_post_request';\n${lift('postRequestPlan')}\n${lift('postEnvelopeMatches')}\n${lift('postRequestKey')}\nreturn { postRequestPlan, postEnvelopeMatches, postRequestKey };`)();

let pass = 0, fail = 0;
const eq = (got, want, label) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  PASS  ${label}`); }
  else { fail++; console.log(`X FAIL  ${label} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
};

const payload = { gross: 84, rating: 71.2, nine_rating: null, slope: 128, holes_played: 18, source: 'quick',
                  played_on: '2026-09-13', course_label: 'Papago', api_course_id: null };
const env = { payload, holes: [], playedWith: [] };

/* no record → fresh */
eq(postRequestPlan(null, env), 'fresh', 'no record: mint, freeze, write, send');
/* a record with no envelope (written by an older build) cannot be replayed verbatim */
eq(postRequestPlan({ id: 'r', at: 1, accepted: null }, env), 'fresh', 'a record without an envelope is not replayable');
/* accepted → finish, whatever the form now says */
eq(postRequestPlan({ id: 'r', accepted: 'round-1', env }, env), 'finish', 'an accepted record finishes the form');
eq(postRequestPlan({ id: 'r', accepted: 'round-1', env }, { ...env, payload: { ...payload, gross: 48 } }), 'finish',
   'an accepted record finishes even over an edited card');
/* same card → replay */
eq(postRequestPlan({ id: 'r', accepted: null, env }, env), 'replay', 'the same card replays the frozen envelope');
/* the frozen envelope carries the uploaded photo path; the live form never does */
eq(postRequestPlan({ id: 'r', accepted: null, env: { ...env, payload: { ...payload, photo_path: 'u/p.jpg' } } }, env), 'replay',
   'the photo path is an upload output and does not make it a different card');
/* an edited card → resolve */
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, payload: { ...payload, gross: 48 } }), 'resolve',
   'a different gross under an unresolved id asks the server');
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, playedWith: ['mate'] }), 'resolve',
   'a changed partner list is a different card');
eq(postRequestPlan({ id: 'r', accepted: null, env }, { ...env, holes: Array(18).fill(4) }), 'resolve',
   'hole scores are part of the envelope');
/* key order does not matter; partner order does not matter */
eq(postEnvelopeMatches({ payload: { b: 1, a: 2 }, holes: [], playedWith: ['x', 'y'] },
                       { payload: { a: 2, b: 1 }, holes: [], playedWith: ['y', 'x'] }), true,
   'matching is by value, not by key or partner order');
eq(postEnvelopeMatches(null, env), false, 'nothing matches nothing');
/* owner scoping */
eq(postRequestKey('u1') === postRequestKey('u2'), false, 'two golfers, two records');
eq(postRequestKey(null), 'cs_post_request.signed-out', 'a signed-out key never collides with an account');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
