// season-email — mail-header text (C-11, 2026-09-25 security review).
//
// The same rule as push/guards.ts `oneLine`, copied rather than shared so each
// function deploys on its own (a `_shared/` folder would read as an undeployed
// function to tools/deploy-status.mjs); tests/edge-security-mail.test.mjs holds
// the two copies equal. No Deno imports, so node --test runs it.

/* a subject (or a recipient's display name) is plain text, but it rides in a
   mail HEADER: one line, no control characters, and short enough to read.
   Cut by code point, so an emoji is never split into half a character. */
export const SUBJECT_MAX = 120;
export function oneLine(s: unknown, max: number): string {
  const t = String(s ?? '')
    .replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const cps = Array.from(t);
  return cps.length <= max ? t : cps.slice(0, max - 1).join('').trimEnd() + '…';
}
