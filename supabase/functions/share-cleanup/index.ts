// Cup Season — share-cleanup. Launch-audit integration I5 (2026-09-24), D385.
//
// A revoked link disables the app's page; it does not remove the public image bytes at
// `shared/{token}.jpg|png`. Migration 20261201090000 records every revocation in
// public.share_cleanup and keeps it `pending` until both copies are CONFIRMED absent.
// This function is the service side of that obligation:
//
//   1 · take the due tokens (_share_cleanup_due — the webhook's own row first),
//   2 · remove both copies through the Storage API (the only route the platform allows;
//       SQL never deletes storage objects, D303),
//   3 · report every attempt (_share_cleanup_report), which RE-VERIFIES absence in
//       storage.objects before it ever says completed, and records the error and the next
//       try (2, 4, 8 … minutes, capped at a day) when it cannot.
//
// Invoked by a Database Webhook on public.share_cleanup (INSERT and UPDATE), and safe to
// invoke on a schedule or by hand: every call also sweeps whatever else is due, so a new
// withdrawal retries older failures and an interrupted run loses nothing.
//
// Auth: shared secret header (x-cleanup-secret); deploy with --no-verify-jwt (the push
// function's pattern). Secrets: SHARE_CLEANUP_SECRET. Never returns a bare `ok` (CLAUDE.md:
// a misrouted webhook must be distinguishable from a no-op), and logs every invocation.
//
// SHARE_CLEANUP_BUCKET exists for failure testing only (a local run pointed at the wrong
// bucket proves the verify-before-complete path); production leaves it unset.

import { createClient } from 'npm:@supabase/supabase-js@2';

const sb = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false } },
);
const SECRET = Deno.env.get('SHARE_CLEANUP_SECRET') ?? '';
const BUCKET = Deno.env.get('SHARE_CLEANUP_BUCKET') ?? 'shared';

type Outcome = { token: string; status: string; error?: string };

async function cleanOne(token: string): Promise<Outcome> {
  let error: string | null = null;
  try {
    const { error: e } = await sb.storage.from(BUCKET).remove([`${token}.jpg`, `${token}.png`]);
    if (e) error = `Storage API: ${e.message}`;
  } catch (e) {
    error = `Storage API unreachable: ${e instanceof Error ? e.message : String(e)}`;
  }
  // the server decides, from storage itself, whether the copies are gone
  const { data, error: re } = await sb.rpc('_share_cleanup_report', { p_token: token, p_error: error });
  if (re) return { token, status: 'report_failed', error: re.message };
  return { token, status: String(data), ...(error ? { error } : {}) };
}

Deno.serve(async (req) => {
  if (!SECRET || req.headers.get('x-cleanup-secret') !== SECRET) {
    console.log('[share-cleanup] refused: missing or wrong x-cleanup-secret');
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
  }
  let first: string | null = null;
  try {
    const body = await req.json();
    const rec = body?.record ?? body;
    if (rec?.token && rec?.status !== 'completed') first = String(rec.token);
  } catch { /* a scheduled or manual call carries no body */ }

  const { data: due, error } = await sb.rpc('_share_cleanup_due', { p_limit: 50 });
  if (error) {
    console.log('[share-cleanup] could not read the queue:', error.message);
    return new Response(JSON.stringify({ error: 'queue_unreadable', detail: error.message }), { status: 500 });
  }
  const tokens = [...new Set([...(first ? [first] : []), ...((due ?? []) as string[])])];
  const results: Outcome[] = [];
  for (const t of tokens) results.push(await cleanOne(t));
  const summary = {
    processed: results.length,
    completed: results.filter((r) => r.status === 'completed').length,
    failed: results.filter((r) => r.status !== 'completed').length,
    results,
  };
  console.log('[share-cleanup]', JSON.stringify({ processed: summary.processed, completed: summary.completed, failed: summary.failed }));
  return new Response(JSON.stringify(summary), { headers: { 'content-type': 'application/json' } });
});
