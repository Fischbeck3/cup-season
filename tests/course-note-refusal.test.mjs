// D403 · a course note the word list refuses, through the REAL caller: the note
// field's save handler in csCourseBooksWire, over the real csRateCourse. The last
// thing on screen must be the canonical refusal (not "Could not save that"), the
// draft stays in the field, the field is released, and the corrected note saves.
// An ordinary transport failure keeps its generic message.
//
// CS_INDEX=<path> runs it against another build (it fails on b3472292).
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const source = readFileSync(process.env.CS_INDEX || new URL('../index.html', import.meta.url), 'utf8');
const between = (a, b) => {
  const i = source.indexOf(a), j = source.indexOf(b, i);
  assert.ok(i >= 0 && j > i, `slice ${a}`);
  return source.slice(i, j);
};
const refusalLine = source.match(/^const CS_MODERATION_REFUSAL = .*$/m)[0];
const rate = between('async function csRateCourse(id, stars, note){', '/* Five drawn stars');
const wire = between('function csCourseBooksWire(box){', '/* one row\'s figures, after a write.');
const REFUSAL = "Cup Season can't take that wording — no slurs, sexual content or threats. Edit it and try again.";
const settle = async () => { for (let i = 0; i < 20; i++) await new Promise(r => setImmediate(r)); };

function page({transportFails = false} = {}) {
  const toasts = [], sent = [];
  const ratings = {c1: {mine: 4, note: null}};
  const sb = {rpc: async (name, args) => {
    assert.equal(name, 'rate_course');
    sent.push(args.p_note);
    if (transportFails) throw new TypeError('Failed to fetch');
    // the database trigger: cs_text_guard raises the canonical sentence
    if (/\bslurword\b/.test(args.p_note || '')) return {error: {message: REFUSAL, hint: 'cs_text_refused'}};
    return {data: {stars: 4, count: 1, mine: 4, mine_note: args.p_note}};
  }};
  const listeners = {};
  const wrap = {dataset: {}};
  const note = {dataset: {csnote: 'c1'}, value: '', disabled: false, parentElement: wrap,
    addEventListener: (ev, fn) => { listeners[ev] = fn; }, blur() { listeners.blur?.(); }};
  const box = {querySelectorAll: sel => sel === 'textarea[data-csnote]' ? [note] : []};
  const context = vm.createContext({
    window: {sb, CS: {user: {id: 'u'}}}, console, String, Number,
    toast: t => toasts.push(t),
    csRatingOf: id => ratings[id] || null,
    csRatingPut: (id, agg) => { ratings[id] = {mine: agg.mine, note: agg.mine_note || null}; return ratings[id]; },
  });
  vm.runInContext(refusalLine + '\n' + rate + wire, context);
  context.csCourseBooksWire(box);
  return {toasts, sent, note, ratings,
    type: async v => { note.value = v; note.blur(); await settle(); }};
}

test('a refused note: the canonical refusal is the last word, the draft stays, the field is free, the fix saves', async () => {
  const p = page();
  await p.type('the slurword greens');
  assert.equal(p.toasts.at(-1), REFUSAL, 'the refusal is not overwritten');
  assert.ok(!p.toasts.includes('Could not save that'));
  assert.equal(p.note.value, 'the slurword greens', 'the draft stays in the field');
  assert.equal(p.note.disabled, false, 'the field is released');
  assert.equal(p.ratings.c1.note, null, 'nothing saved');

  await p.type('fast greens, firm fairways');
  assert.equal(p.toasts.at(-1), 'Saved');
  assert.equal(p.ratings.c1.note, 'fast greens, firm fairways');
  assert.deepEqual(p.sent, ['the slurword greens', 'fast greens, firm fairways']);
});

test('an ordinary transport failure keeps the generic message and the draft', async () => {
  const p = page({transportFails: true});
  await p.type('fast greens');
  assert.equal(p.toasts.at(-1), 'Could not save that');
  assert.equal(p.note.value, 'fast greens');
  assert.equal(p.note.disabled, false);
});
