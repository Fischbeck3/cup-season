// courses — what a request may cost upstream, and what the ledger answered
// (C-04, 2026-09-25 security review; prior audit F3).
//
// The daily caps count GolfCourseAPI CALLS, not invocations. `_courses_reserve`
// books a request's units atomically BEFORE it may spend any, and the function
// refuses when it cannot book — so the number here is the MOST a request can
// spend, read off index.ts:
//   · search — one search call, then up to SEARCH_DETAIL_FETCHES detail fetches
//     for courses the provider sent without tees and our dataset lacks;
//   · cache  — at most one fetch (a miss, or a stale card's background refresh);
//   · a request that cannot reach the provider (a query under 3 characters, no
//     id, an unknown action) books nothing and is answered without a call.
// No Deno imports, so node --test runs it (the normalize.ts pattern).

/* index.ts's search loop stops at this same constant, so the booking and the
   spending cannot drift apart */
export const SEARCH_DETAIL_FETCHES = 3;

export function unitsFor(action: unknown, body: unknown): number {
  const b = (body && typeof body === 'object' ? body : {}) as Record<string, unknown>;
  if (action === 'search') return String(b.q ?? '').trim().length < 3 ? 0 : 1 + SEARCH_DETAIL_FETCHES;
  if (action === 'cache') return String(b.id ?? '').trim() ? 1 : 0;
  return 0;
}

/* the reservation's answer as the caller's response. Only a clean 'ok' spends:
   an RPC error, a null, a word this code does not know — each refuses (503),
   because the ledger is the only thing between one account and the shared
   quota and it must never fail open */
export type Verdict = { ok: true } | { ok: false; status: number; error: string };
export function reservation(data: unknown, error: unknown): Verdict {
  if (!error && data === 'ok') return { ok: true };
  if (!error && data === 'user_cap') return { ok: false, status: 429, error: 'daily course-lookup limit reached' };
  if (!error && data === 'global_cap') return { ok: false, status: 429, error: 'course lookups are paused for today' };
  return { ok: false, status: 503, error: 'course lookup unavailable' };
}
