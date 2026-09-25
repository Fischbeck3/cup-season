// push — the pure rules behind the 2026-09-25 security review (C-01, C-02, C-08).
//
// No Deno and no npm imports, so `node --experimental-strip-types --test` runs
// them directly (the courses/normalize.ts pattern); index.ts is the only caller.

/* C-01 · a display name is the golfer's own text, and the friend-request email
   is signed by our domain. Every value that reaches HTML goes through here —
   nothing is trusted because it looks like a name (`<a/href=…>` needs no space,
   so firstName() was never a defence). */
export function escapeHtml(s: unknown): string {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
}

/* the requester's name as a friend-request email may carry it: the first word,
   letters only (apostrophes and hyphens kept), 20 at most. This is the rule the
   database applies to a stranger's push (_nudge_guard, D392), so the email cannot
   carry what the lock screen no longer can: no digits, dots or slashes means no
   phone number and no URL for a mail client to turn into a link. */
export function mailName(n: unknown): string {
  const first = String(n ?? '').trim().split(/\s+/)[0] ?? '';
  const kept = Array.from(first.replace(/[^\p{L}\p{M}'-]/gu, '')).slice(0, 20).join('');
  return /\p{L}/u.test(kept) ? kept : 'A golfer';   // '1-800-555' leaves only dashes
}

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

/* C-01 · who may be sent a Cup Season email, as the reason NOT to (null = send).
   The rule is friend_request()'s own (D392): a finished card has a handle and no
   deleted_at. An OTP sign-up mints a profile before anyone proves the address
   (CLAUDE.md, the signup trigger), so an unfinished card is an email address,
   not a golfer. And no address on a reserved TLD (is_undeliverable, 20260901200000),
   which also covers delete_account's `deleted+…@cupseason.invalid` tombstone. */
export type Addressee = {
  email?: string | null; handle?: string | null; deleted_at?: string | null;
} | null | undefined;
export function emailSkip(p: Addressee): string | null {
  if (!p) return 'no-profile';
  if (p.deleted_at) return 'deleted';
  if (!String(p.handle ?? '').trim()) return 'unfinished-card';
  const e = String(p.email ?? '').trim().toLowerCase();
  if (!e || /\.(test|example|invalid|localhost)$/.test(e)) return 'undeliverable';
  return null;
}

/* C-02 · the author of a push_nudges row, for the mute check. `sender_id` is
   stamped by the BEFORE INSERT trigger from auth.uid() (D392), so whoever wrote
   the payload cannot choose it; a system row (cron, the founder's tooling)
   carries none and keeps the payload's profile_id, as before. */
const present = (v: unknown) => v !== undefined && v !== null && v !== '';
export function nudgeAuthor(
  record: { sender_id?: unknown } | null | undefined,
  payload: { profile_id?: unknown } | null | undefined,
): string | null {
  const s = present(record?.sender_id) ? record?.sender_id : payload?.profile_id;
  return present(s) ? String(s) : null;
}

/* C-08 · no outbound call may hold the rest hostage. A web-push endpoint is a
   URL a golfer registered, and one that never answered used to stall APNs for
   the whole league. The clock wins the race; the late answer is ignored. */
export function withTimeout<T>(p: Promise<T>, ms: number, what: string): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const clock = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${what} timed out after ${ms}ms`)), ms);
  });
  return Promise.race([p, clock]).finally(() => clearTimeout(timer));
}
