// The courses function's numeric normalization (supabase/functions/courses/normalize.ts).
// Run: node --experimental-strip-types --test tests/courses-normalize.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { num, int, holeCount } from '../supabase/functions/courses/normalize.ts';

test('null and undefined stay null — a missing fact is never a zero', () => {
  assert.equal(num(null), null);
  assert.equal(num(undefined), null);
  assert.equal(int(null), null);
  assert.equal(int(undefined), null);
});

test('booleans and other non-numeric types become null, never 0 or 1', () => {
  for (const v of [true, false, {}, [], [1], { n: 1 }, Symbol('x'), 10n, () => 1]) {
    assert.equal(num(v), null, `num(${String(v)})`);
    assert.equal(int(v), null, `int(${String(v)})`);
  }
});

test('finite numbers pass; NaN and infinities do not', () => {
  assert.equal(num(72.4), 72.4);
  assert.equal(num(0), 0);
  assert.equal(num(-3), -3);
  assert.equal(num(NaN), null);
  assert.equal(num(Infinity), null);
  assert.equal(num(-Infinity), null);
});

test('numeric strings are numbers; empty and non-numeric strings are null', () => {
  assert.equal(num('113'), 113);
  assert.equal(num(' 72.4 '), 72.4);
  assert.equal(num(''), null);
  assert.equal(num('   '), null);
  assert.equal(num('abc'), null);
  assert.equal(num('12abc'), null);
});

test('integers round from finite numbers only', () => {
  assert.equal(int(113.5), 114);
  assert.equal(int('113.4'), 113);
  assert.equal(int(6800.2), 6800);
  assert.equal(int('x'), null);
  assert.equal(int(true), null);
});

test('the hole count: the number said, else the holes listed, else null', () => {
  assert.equal(holeCount(18, []), 18);
  assert.equal(holeCount('9', []), 9);
  assert.equal(holeCount(null, [{}, {}, {}]), 3);
  assert.equal(holeCount(undefined, [{}, {}, {}, {}, {}, {}, {}, {}, {}]), 9);
  assert.equal(holeCount(0, []), null);          // a zero said is not a count
  assert.equal(holeCount(null, []), null);       // nothing said, nothing listed: unknown, not 0
  assert.equal(holeCount(null, null), null);
  assert.equal(holeCount(true, [{}]), 1);        // a boolean is not a count; the listing is
  assert.equal(holeCount(-1, [{}, {}]), 2);
});
