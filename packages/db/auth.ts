/* Cup Season — shared auth (D98 Phase B1).
 *
 * Sibling to client.ts and built the same way: dependency-free, a structural
 * view of the Supabase client rather than an import of it, so the phone app
 * and the Phase D desktop rewrite can be on different supabase-js versions.
 *
 * This file exists because the OTP rules were prose. They lived in comments in
 * index.html, which meant the second client would have re-learned every one of
 * them the hard way. Here they are shapes instead:
 *
 *   - No `emailRedirectTo`, ever. Not "we remember not to" — requestEmailCode
 *     takes an email and nothing else, so there is no parameter to pass it
 *     through. Gmail's link scanner consumes single-use tokens before the user
 *     clicks; every link-bearing template this project has tried has burned.
 *   - Codes are EIGHT digits. Supabase issues 8, not 6. A `maxlength=6` input
 *     cost this project a debugging session; OTP_LENGTH is the only number a
 *     UI should ever read.
 *   - No auth call runs synchronously inside onAuthStateChange. `onAuth` wraps
 *     the handler in deferAuthWork, so a handler that calls getSession cannot
 *     deadlock the internal lock with zero error output.
 */

import { deferAuthWork } from './client';

/* ---------------------------------------------------------------------------
 * The shape we need. Structural on purpose — see client.ts.
 * ------------------------------------------------------------------------ */
export interface AuthError { message: string; status?: number; code?: string }

export interface Session {
  access_token: string;
  refresh_token: string;
  expires_at?: number;
  user: { id: string; email?: string };
}

export type AuthEvent =
  | 'INITIAL_SESSION' | 'SIGNED_IN' | 'SIGNED_OUT'
  | 'TOKEN_REFRESHED' | 'USER_UPDATED' | 'PASSWORD_RECOVERY'
  | (string & {});

export interface AuthLike {
  auth: {
    signInWithOtp(creds: { email: string }): PromiseLike<{ error: AuthError | null }>;
    verifyOtp(creds: { email: string; token: string; type: 'email' }):
      PromiseLike<{ data: { session: Session | null }; error: AuthError | null }>;
    getSession(): PromiseLike<{ data: { session: Session | null }; error: AuthError | null }>;
    signOut(): PromiseLike<{ error: AuthError | null }>;
    onAuthStateChange(cb: (event: AuthEvent, session: Session | null) => void):
      { data: { subscription: { unsubscribe(): void } } };
  };
}

export class AuthCallError extends Error {
  constructor(readonly op: string, readonly cause: AuthError) {
    super(`${op}: ${cause.message}`);
    this.name = 'AuthCallError';
  }
}

/* ---------------------------------------------------------------------------
 * The code itself.
 *
 * Supabase issues 8-digit OTPs. Never render an input that caps at 6, and read
 * the length from here rather than typing a literal.
 * ------------------------------------------------------------------------ */
export const OTP_LENGTH = 8;

/** Strip everything that is not a digit and keep at most OTP_LENGTH of them.
 *  Safe to run on every keystroke — pasted codes arrive with spaces and
 *  non-breaking hyphens from mail clients. */
export function normalizeCode(raw: string): string {
  return (raw || '').replace(/\D/g, '').slice(0, OTP_LENGTH);
}

/** True once the user has typed or pasted a full code. Drive auto-submit off
 *  this, not off a hand-written length comparison. */
export function isCompleteCode(raw: string): boolean {
  return normalizeCode(raw).length === OTP_LENGTH;
}

export function normalizeEmail(raw: string): string {
  return (raw || '').trim().toLowerCase();
}

export function looksLikeEmail(raw: string): boolean {
  const e = normalizeEmail(raw);
  return e.length > 3 && e.includes('@') && !e.includes(' ') && !e.startsWith('@') && !e.endsWith('@');
}

/* ---------------------------------------------------------------------------
 * Request a code.
 *
 * The signature is the safety mechanism: an email, and nothing else. There is
 * deliberately no options bag, because an options bag is where emailRedirectTo
 * would eventually be added by someone who did not know why it must not be.
 * ------------------------------------------------------------------------ */
export async function requestEmailCode(client: AuthLike, email: string): Promise<void> {
  const to = normalizeEmail(email);
  if (!looksLikeEmail(to)) throw new AuthCallError('requestEmailCode', { message: 'That does not look like an email address.' });
  const { error } = await client.auth.signInWithOtp({ email: to });
  if (error) throw new AuthCallError('requestEmailCode', error);
}

/** Verify a code and return the session it minted. Accepts raw user input —
 *  normalization happens here so no caller has to remember to do it. */
export async function verifyEmailCode(client: AuthLike, email: string, code: string): Promise<Session> {
  const to = normalizeEmail(email);
  const token = normalizeCode(code);
  if (token.length !== OTP_LENGTH) {
    throw new AuthCallError('verifyEmailCode', { message: `Type all ${OTP_LENGTH} digits from the email.` });
  }
  const { data, error } = await client.auth.verifyOtp({ email: to, token, type: 'email' });
  if (error) throw new AuthCallError('verifyEmailCode', error);
  if (!data.session) throw new AuthCallError('verifyEmailCode', { message: 'The code was accepted but no session came back.' });
  return data.session;
}

export async function currentSession(client: AuthLike): Promise<Session | null> {
  const { data, error } = await client.auth.getSession();
  if (error) throw new AuthCallError('currentSession', error);
  return data.session;
}

export async function signOut(client: AuthLike): Promise<void> {
  const { error } = await client.auth.signOut();
  if (error) throw new AuthCallError('signOut', error);
}

/* ---------------------------------------------------------------------------
 * Subscribe to auth changes.
 *
 * The handler is deferred to a microtask, which is what makes it safe for it
 * to call another auth method. Calling one synchronously inside the callback
 * deadlocks Supabase's internal auth lock and prints nothing at all — the
 * worst failure mode in this codebase's history, because there is no error to
 * search for. Returns an unsubscribe function.
 * ------------------------------------------------------------------------ */
export function onAuth(
  client: AuthLike,
  handler: (event: AuthEvent, session: Session | null) => void | Promise<void>,
): () => void {
  const { data } = client.auth.onAuthStateChange(deferAuthWork(handler));
  return () => data.subscription.unsubscribe();
}

/* ---------------------------------------------------------------------------
 * Human-readable failures.
 *
 * Supabase's auth messages are written for developers. The one thing a person
 * needs to know at the code screen is that resending invalidates the older
 * code, which is the single most common cause of "it says invalid".
 * ------------------------------------------------------------------------ */
export function humanAuthError(e: unknown, fallback = 'That did not take.'): string {
  const m = (e instanceof AuthCallError ? e.cause.message : e instanceof Error ? e.message : '') || '';
  const s = m.toLowerCase();
  if (s.includes('expired') || (s.includes('invalid') && s.includes('token'))) {
    return 'That code has expired. Codes expire when a new one is sent — use the newest email.';
  }
  if (s.includes('rate limit') || s.includes('too many')) {
    return 'Too many tries in a row. Give it a minute and ask for a fresh code.';
  }
  if (s.includes('network') || s.includes('fetch')) {
    return 'Could not reach the server. Check your connection and try again.';
  }
  return m || fallback;
}
