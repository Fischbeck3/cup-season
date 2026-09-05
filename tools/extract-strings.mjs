#!/usr/bin/env node
/* Cup Season — the string extractor (D249 / IOS-036, TERMINOLOGY.md §4.1).

   The vocabulary lint's rule is "exempt by CALL SITE, not by file": a string is
   exempt because it is an identifier, never because of where it lives. A grep
   cannot do that. Two patterns proved it at tip, both measured:

     · `differential` hits `.select("id,differential,…")` — a column list.
     · `bylaws` hits a property path inside an interpolation segment, not a
       word a golfer reads.

   So the lint reads PROSE, and prose is what this file produces: every string
   literal a golfer could meet, with the call it sits in, and nothing else.

     node tools/extract-strings.mjs swift <file…>   -> one JSON line per string
     node tools/extract-strings.mjs web             -> index.html's own
     node tools/extract-strings.mjs sql             -> the migrations' literals
     node tools/extract-strings.mjs count           -> a per-source tally

   Read-only. Imported by tests/preflight.mjs check 27. */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

/* Positional identifiers: a literal handed to one of these is a column, a
   table, an RPC name or a filter — never prose (§4.1 rule 2). */
export const IDENTIFIER_CALLS = new Set([
  'select', 'eq', 'neq', 'in', 'is', 'gt', 'gte', 'lt', 'lte', 'like', 'ilike',
  'order', 'rpc', 'from', 'contains', 'filter', 'not', 'or', 'match',
  'setValue', 'decodeIfPresent', 'decode', 'encode', 'forKey',
  'set', 'removeObject', 'integer', 'register', 'string', 'bool', 'double',
  'object', 'array', 'value', 'data', 'addObserver', 'Notification',
  /* the web's own selectors: `$('#bylawsHub')` names an element, not a word */
  '$', 'querySelector', 'querySelectorAll', 'getElementById', 'closest', 'matches',
  'createElement', 'setAttribute', 'getAttribute', 'add', 'remove', 'toggle',
]);

/* Prose by position even when the argument looks like a key (§4.1 rule 5). */
export const PROSE_CALLS = new Set(['accessibilityLabel', 'accessibilityHint', 'accessibilityValue']);

/* ── Swift ─────────────────────────────────────────────────────────────────
   A hand-rolled scanner rather than a regex: Swift has line comments, nested
   block comments, triple-quoted blocks, raw strings and interpolation that can
   itself contain strings. Every one of those appears in this repo. */
export function swiftStrings(src) {
  const out = [];
  const n = src.length;
  let i = 0, depth = 0;                        // depth: block-comment nesting
  const lineStarts = [0];
  for (let k = 0; k < n; k++) if (src[k] === '\n') lineStarts.push(k + 1);
  const lineOf = idx => {
    let lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (lineStarts[mid] <= idx) lo = mid; else hi = mid - 1; }
    return lo + 1;
  };

  /* the call a literal starting at `idx` sits in: walk back over balanced
     brackets to the paren that opened this argument list, then read the name. */
  const callAt = idx => {
    let k = idx - 1, bal = 0;
    while (k >= 0) {
      const c = src[k];
      if (c === ')' || c === ']' || c === '}') bal++;
      else if (c === '(' || c === '[' || c === '{') {
        if (bal === 0) { if (c !== '(') return ''; break; }
        bal--;
      }
      k--;
    }
    if (k < 0) return '';
    let s = k - 1;
    while (s >= 0 && /\s/.test(src[s])) s--;
    const end = s;
    while (s >= 0 && /[A-Za-z0-9_]/.test(src[s])) s--;
    return src.slice(s + 1, end + 1);
  };

  const push = (text, idx, call) => { if (text) out.push({ text, line: lineOf(idx), call }); };

  while (i < n) {
    const c = src[i];
    if (depth > 0) {
      if (c === '/' && src[i + 1] === '*') { depth++; i += 2; continue; }
      if (c === '*' && src[i + 1] === '/') { depth--; i += 2; continue; }
      i++; continue;
    }
    if (c === '/' && src[i + 1] === '/') { while (i < n && src[i] !== '\n') i++; continue; }
    if (c === '/' && src[i + 1] === '*') { depth = 1; i += 2; continue; }
    if (c === '"' || (c === '#' && src[i + 1] === '"')) {
      const start = i;
      const hashes = c === '#' ? 1 : 0;
      let j = i + hashes;
      const triple = src.slice(j, j + 3) === '"""';
      const close = triple ? '"""' : '"';
      j += close.length;
      let text = '';
      while (j < n) {
        if (src[j] === '\\' && !hashes) {
          if (src[j + 1] === '(') {              // rule 3 — skip the expression,
            let bal = 1, k = j + 2;              // but keep any literal inside it
            while (k < n && bal > 0) {
              if (src[k] === '(') bal++;
              else if (src[k] === ')') bal--;
              else if (src[k] === '"') {
                let m = k + 1, inner = '';
                while (m < n && src[m] !== '"') { if (src[m] === '\\') { inner += src[m + 1]; m += 2; continue; } inner += src[m]; m++; }
                push(inner, k, callAt(start));
                k = m;
              }
              k++;
            }
            text += ' ';                         // a seam: never a word boundary
            j = k; continue;
          }
          text += src[j + 1] === 'n' ? '\n' : src[j + 1];
          j += 2; continue;
        }
        if (src.slice(j, j + close.length) === close && (!hashes || src[j + close.length] === '#')) {
          j += close.length + (hashes ? 1 : 0);
          break;
        }
        text += src[j]; j++;
      }
      push(text, start, callAt(start));
      i = j; continue;
    }
    i++;
  }
  return out;
}

/* Enum raw values and CodingKeys are wire names (§4.1 rule 4). Detected on the
   source line rather than by call, because a `case x = "x"` has no call at all. */
export function isSwiftWireName(srcLines, s) {
  const l = srcLines[s.line - 1] || '';
  return /^\s*case\s+[A-Za-z0-9_]+\s*=\s*"/.test(l) || /CodingKeys/.test(l);
}

const COLUMN_LIST = /^[a-z0-9_]+(?:\s*[,:]\s*[a-z0-9_()!.*]+)+$/i;

/* An identifier by SHAPE, not by file (§4's own rule): a bare lowercase snake
   token (`duel`, `commissioner`, `squads2`), a dotted path, a storage key or a
   URL. A sentence a golfer reads has a capital, a space or punctuation in it;
   none of these do. This is what lets patterns 6, 9, 10 and 12 ship at all —
   without it the lint fails on `case "duel"` and gets disabled. */
export const IDENTIFIER_SHAPE = [
  /^[a-z][a-z0-9_-]*$/,
  /^[a-z0-9_]+(?:\.[a-z0-9_]+)+$/,
  /^[a-z]+:[/][/]/,
  /^[A-Za-z0-9_]+$/,
];
const looksLikeIdentifier = t => { const x = t.trim(); return x.length < 40 && IDENTIFIER_SHAPE.some(re => re.test(x)); };

/* A JSON payload (a decode fixture, a sample body) and a REGEX pattern are
   both machine text: neither is a sentence anybody reads. Measured on
   `PricingParts.swift:116` (a `Me.Membership` fixture) and
   `PeopleModels.swift:152` (an auth-error pattern), which are the two shapes
   in the tree. */
const looksLikePayload = t => {
  const x = t.trim();
  if (/^[[{][\s\S]*[\]}],?$/.test(x) && /"\s*:/.test(x)) return true;          // JSON
  if ((x.match(/\|/g) || []).length >= 2 && !/[.!?]\s/.test(x)) return true;    // a pattern
  return false;
};

export function swiftProse(src, { file = '' } = {}) {
  const lines = src.split('\n');
  return swiftStrings(src).filter(s => {
    if (PROSE_CALLS.has(s.call)) return true;
    if (IDENTIFIER_CALLS.has(s.call)) return false;
    if (isSwiftWireName(lines, s)) return false;
    if (COLUMN_LIST.test(s.text)) return false;
    if (looksLikeIdentifier(s.text) || looksLikePayload(s.text)) return false;
    return true;
  }).map(s => ({ ...s, file }));
}

/* ── the web ───────────────────────────────────────────────────────────────
   index.html is one file of classic script, one module block and the markup.
   Template literals carry expression spans (the same trap as Swift's
   interpolation) and `sb.from(x).select('a,b,c')` carries the same column
   lists. */
export function webStrings(src) {
  const out = [];
  const n = src.length;
  let i = 0;
  const lineStarts = [0];
  for (let k = 0; k < n; k++) if (src[k] === '\n') lineStarts.push(k + 1);
  const lineOf = idx => {
    let lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (lineStarts[mid] <= idx) lo = mid; else hi = mid - 1; }
    return lo + 1;
  };
  const callAt = idx => {
    let k = idx - 1, bal = 0;
    while (k >= 0) {
      const c = src[k];
      if (c === ')' || c === ']') bal++;
      else if (c === '(') { if (bal === 0) break; bal--; }
      else if (c === '[') { if (bal === 0) return ''; bal--; }
      else if (c === ';' || c === '{' || c === '}') { if (bal === 0) return ''; }
      k--;
    }
    if (k < 0) return '';
    let s = k - 1;
    while (s >= 0 && /\s/.test(src[s])) s--;
    const end = s;
    while (s >= 0 && /[A-Za-z0-9_$]/.test(src[s])) s--;
    return src.slice(s + 1, end + 1);
  };

  /* A regex literal is not a string, and `/'/g` inside a template expression
     opened one until this existed (index.html:22472). Regex-or-divide is
     decided the way a tokeniser decides it: by the previous meaningful char. */
  const regexAt = k => {
    if (src[k] !== '/' || src[k + 1] === '/' || src[k + 1] === '*') return -1;
    let p = k - 1;
    while (p >= 0 && /\s/.test(src[p])) p--;
    if (p >= 0 && !/[([{,;:=!&|?+\-*%~^<>]/.test(src[p]) && !/\breturn$|\btypeof$|\bcase$/.test(src.slice(Math.max(0, p - 8), p + 1))) return -1;
    let m = k + 1, cls = false;
    while (m < n) {
      if (src[m] === '\\') { m += 2; continue; }
      if (src[m] === '[') cls = true;
      else if (src[m] === ']') cls = false;
      else if (src[m] === '/' && !cls) return m + 1;
      else if (src[m] === '\n') return -1;
      m++;
    }
    return -1;
  };

  while (i < n) {
    const c = src[i];
    { const r = regexAt(i); if (r > 0) { i = r; continue; } }
    if (c === '<' && src.slice(i, i + 4) === '<!--') { i += 4; while (i < n && src.slice(i, i + 3) !== '-->') i++; i += 3; continue; }
    if (c === '/' && src[i + 1] === '/' && (src[i - 1] || ' ') !== ':') { while (i < n && src[i] !== '\n') i++; continue; }
    if (c === '/' && src[i + 1] === '*') { i += 2; while (i < n && !(src[i] === '*' && src[i + 1] === '/')) i++; i += 2; continue; }
    if (c === '"' || c === "'" || c === '`') {
      const start = i, q = c;
      let j = i + 1, text = '';
      while (j < n) {
        if (src[j] === '\\') {
          if (src[j + 1] === 'u' && /^[0-9a-fA-F]{4}$/.test(src.slice(j + 2, j + 6))) {
            text += String.fromCharCode(parseInt(src.slice(j + 2, j + 6), 16)); j += 6; continue;
          }
          text += src[j + 1]; j += 2; continue;
        }
        if (q === '`' && src[j] === '$' && src[j + 1] === '{') {
          let bal = 1, k = j + 2;
          while (k < n && bal > 0) {
            { const r = regexAt(k); if (r > 0) { k = r; continue; } }
            if (src[k] === '/' && src[k + 1] === '*') { k += 2; while (k < n && !(src[k] === '*' && src[k + 1] === '/')) k++; k += 2; continue; }
            if (src[k] === '/' && src[k + 1] === '/' && (src[k - 1] || ' ') !== ':') { while (k < n && src[k] !== '\n') k++; continue; }
            if (src[k] === '{') bal++;
            else if (src[k] === '}') bal--;
            else if (src[k] === '`' || src[k] === "'" || src[k] === '"') {
              const qq = src[k];
              let m = k + 1, inner = '';
              while (m < n && src[m] !== qq) { if (src[m] === '\\') { inner += src[m + 1]; m += 2; continue; } if (qq === '`' && src[m] === '$' && src[m + 1] === '{') { let b2 = 1; m += 2; while (m < n && b2 > 0) { if (src[m] === '{') b2++; else if (src[m] === '}') b2--; m++; } inner += ' '; continue; } inner += src[m]; m++; }
              if (inner) out.push({ text: inner, line: lineOf(k), call: callAt(start) });
              k = m;
            }
            k++;
          }
          text += ' '; j = k; continue;
        }
        if (src[j] === q) { j++; break; }
        if (src[j] === '\n' && q !== '`') { j++; break; }
        text += src[j]; j++;
      }
      out.push({ text, line: lineOf(start), call: callAt(start) });
      i = j; continue;
    }
    i++;
  }
  return out;
}

export function webProse(src) {
  return webStrings(src).filter(s => {
    if (!s.text) return false;
    if (IDENTIFIER_CALLS.has(s.call)) return false;
    if (COLUMN_LIST.test(s.text)) return false;
    if (looksLikeIdentifier(s.text) || looksLikePayload(s.text)) return false;
    return true;
  });
}

/* ── SQL ───────────────────────────────────────────────────────────────────
   The board, push and ledger generators write sentences a golfer reads. Only
   single-quoted literals count. */
export function sqlStrings(src) {
  const out = [];
  /* `--` comments and dollar-quoted tags are not sentences a golfer meets */
  src = src.replace(/--[^\n]*/g, m => ' '.repeat(m.length));
  const re = /'((?:[^']|'')*)'/g;
  const lineStarts = [0];
  for (let k = 0; k < src.length; k++) if (src[k] === '\n') lineStarts.push(k + 1);
  const lineOf = idx => {
    let lo = 0, hi = lineStarts.length - 1;
    while (lo < hi) { const mid = (lo + hi + 1) >> 1; if (lineStarts[mid] <= idx) lo = mid; else hi = mid - 1; }
    return lo + 1;
  };
  let m;
  while ((m = re.exec(src))) out.push({ text: m[1].replace(/''/g, "'"), line: lineOf(m.index), call: '' });
  return out;
}

/* ── the sources the lint reads (§4 scope) ─────────────────────────────── */
export const SWIFT_SKIP_DIRS = new Set(['build', '.build', 'DerivedData', 'CupSeason.xcodeproj', 'Screenshots', 'Tests']);
export function swiftSources(iosRoot) {
  const files = [];
  const walk = dir => {
    let entries;
    try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (e.name.startsWith('.') && e.name !== '.build') continue;
      if (SWIFT_SKIP_DIRS.has(e.name)) continue;
      const full = join(dir, e.name);
      if (e.isDirectory()) { if (full.endsWith('/Generated')) continue; walk(full); }
      else if (e.name.endsWith('.swift')) files.push(full);
    }
  };
  if (existsSync(iosRoot)) walk(iosRoot);
  return files;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const root = new URL('..', import.meta.url).pathname;
  const mode = process.argv[2] || 'count';
  if (mode === 'swift') {
    for (const f of process.argv.slice(3)) {
      for (const s of swiftProse(readFileSync(f, 'utf8'), { file: f })) console.log(JSON.stringify(s));
    }
  } else if (mode === 'web') {
    for (const s of webProse(readFileSync(join(root, 'index.html'), 'utf8'))) console.log(JSON.stringify(s));
  } else if (mode === 'sql') {
    const dir = join(root, 'supabase', 'migrations');
    for (const f of readdirSync(dir).filter(x => x.endsWith('.sql'))) {
      for (const s of sqlStrings(readFileSync(join(dir, f), 'utf8'))) console.log(JSON.stringify({ ...s, file: f }));
    }
  } else {
    const swift = swiftSources(join(root, 'apps', 'ios'));
    let sc = 0;
    for (const f of swift) sc += swiftProse(readFileSync(f, 'utf8'), { file: f }).length;
    const web = webProse(readFileSync(join(root, 'index.html'), 'utf8')).length;
    console.log(`swift ${swift.length} file(s) · ${sc} string(s) · web ${web} string(s)`);
  }
}
