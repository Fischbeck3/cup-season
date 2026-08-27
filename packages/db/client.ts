/* Cup Season — the shared data layer (D98 Phase A3).
 *
 * Every client — the React Native phone app, the React desktop rewrite, and
 * anything after them — calls Postgres through here. It is deliberately
 * dependency-free: it takes a structural view of a Supabase client rather than
 * importing one, so it compiles standalone and never pins a supabase-js
 * version across three surfaces that will upgrade on different days.
 *
 * What lives here is the set of rules this codebase has already paid to learn.
 * They are encoded, not documented, because a documented rule is one a tired
 * person skips at 11pm.
 */

import type { Rpc, RpcName } from './rpc';

/* The shape we need from a Supabase client. Structural on purpose. */
export interface PostgrestLike {
  rpc(fn: string, args?: Record<string, unknown>): PromiseLike<{ data: unknown; error: DbError | null }>;
}
export interface DbError { message: string; code?: string; details?: string | null }

export class RpcError extends Error {
  constructor(readonly fn: string, readonly cause: DbError, readonly droppedArgs?: string[]) {
    super(`${fn}: ${cause.message}`);
    this.name = 'RpcError';
  }
}

/* ---------------------------------------------------------------------------
 * Deploy skew.
 *
 * Netlify can serve a new client before its migration is pushed, or after. A
 * call carrying an argument the deployed function does not have yet must
 * degrade, not fail.
 *
 * The rule that matters, and the one that cost a boot: retry on ANY error,
 * never on the message. When `photo_path` shipped ahead of its column grant,
 * Postgres answered 42501 "permission denied for table profiles" — a message
 * that never names the column. Every message-sniffing retry missed it and the
 * app died at the card gate. So: if optional args were supplied and the call
 * failed for any reason at all, drop them and try once more. A second failure
 * is real and is thrown.
 * ------------------------------------------------------------------------ */
export interface CallOptions<N extends RpcName> {
  /** Args safe to drop and retry without if the deployed function is older. */
  skewOptional?: (keyof Rpc[N]['args'])[];
}

export async function call<N extends RpcName>(
  db: PostgrestLike,
  fn: N,
  args: Rpc[N]['args'],
  opts: CallOptions<N> = {},
): Promise<Rpc[N]['returns']> {
  const payload = { ...(args as Record<string, unknown>) };
  const first = await db.rpc(fn, payload);
  if (!first.error) return first.data as Rpc[N]['returns'];

  const droppable = (opts.skewOptional ?? []).map(String).filter((k) => k in payload);
  if (!droppable.length) throw new RpcError(fn, first.error);

  for (const k of droppable) delete payload[k];
  const second = await db.rpc(fn, payload);
  if (second.error) throw new RpcError(fn, second.error, droppable);
  return second.data as Rpc[N]['returns'];
}

/* A caller that has already bound its client. */
export const rpcClient = (db: PostgrestLike) => ({
  call: <N extends RpcName>(fn: N, args: Rpc[N]['args'], opts?: CallOptions<N>) =>
    call(db, fn, args, opts),
});

/* ---------------------------------------------------------------------------
 * Realtime.
 *
 * Channels live on a DEDICATED client, never the one serving queries and auth.
 * Verified the hard way: a raw socket and a fresh client both subscribed fine
 * on the same machine and token while the busy client failed with
 * CHANNEL_ERROR / transport failure. Forward tokens on auth change; do not
 * move subscriptions back onto the main client.
 * ------------------------------------------------------------------------ */
export interface RealtimeLike { realtime: { setAuth(token: string): void } }

export function bindRealtimeAuth(rt: RealtimeLike) {
  return (accessToken: string | null | undefined) => {
    if (accessToken) rt.realtime.setAuth(accessToken);
  };
}

/* ---------------------------------------------------------------------------
 * Auth.
 *
 * NEVER call a Supabase auth method synchronously inside onAuthStateChange —
 * the internal auth lock deadlocks with no error output at all. Defer to a
 * microtask and the lock is released first. Wrap every handler in this.
 * ------------------------------------------------------------------------ */
export function deferAuthWork<A extends unknown[]>(fn: (...a: A) => void | Promise<void>) {
  return (...a: A) => { queueMicrotask(() => { void fn(...a); }); };
}

/* ---------------------------------------------------------------------------
 * Dates.
 *
 * `new Date('YYYY-MM-DD')` parses as UTC midnight and renders the PREVIOUS day
 * in Phoenix. Build and read calendar dates by parts, in both directions.
 * ------------------------------------------------------------------------ */
export function localDate(iso: string): Date {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d);
}
export function isoDate(dt: Date): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${dt.getFullYear()}-${p(dt.getMonth() + 1)}-${p(dt.getDate())}`;
}
