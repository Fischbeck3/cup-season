// Cup Season — share-cleanup. Launch-audit integration I5 (2026-09-24), D385.
//
// A revoked link disables the app's page; it does not remove the public image bytes at
// `shared/{token}.jpg|png`. Migration 20261201090000 records every revocation in
// public.share_cleanup and keeps it `pending` until both copies are CONFIRMED absent.
// This function is the service side of that obligation:
//
//   1 · take only the due tokens (_share_cleanup_due owns retry timing),
//   2 · remove both copies through the Storage API (the only route the platform allows;
//       SQL never deletes storage objects, D303),
//   3 · report every attempt (_share_cleanup_report), which RE-VERIFIES absence in
//       storage.objects before it ever says completed, and records the error and the next
//       try (2, 4, 8 … minutes, capped at a day) when it cannot.
//
// Invoked every minute by a REQUIRED schedule; a Database Webhook can also wake it
// on withdrawals. The schedule reclaims abandoned preparations and retries failures
// even if no golfer opens the app or changes the queue again. A webhook payload is
// only a wakeup: trusting its row would bypass backoff and recurse on error reports.
//
// D395 · the same obligation for a DELETED ACCOUNT's photos: every object under
// `media/<profile_id>/`, queued by delete_account in public.account_media_cleanup, taken
// only when due (_media_cleanup_due), removed through the Storage API, and reported per
// profile (_media_cleanup_report), which re-verifies storage.objects the same way.
//
// Auth: shared secret header (x-cleanup-secret); deploy with --no-verify-jwt (the push
// function's pattern; pinned in supabase/config.toml since C-05). Secrets:
// SHARE_CLEANUP_SECRET. Never returns a bare `ok` (CLAUDE.md: a misrouted webhook must
// be distinguishable from a no-op), and logs every invocation.
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

// ---- D395 · a deleted account's photos ----------------------------------------------
// Today's layout is flat (`<uid>/<photo>.jpg`, `<uid>/avatar.jpg`), but the walk follows
// folders anyway, bounded: MEDIA_DEPTH levels, pages of MEDIA_PAGE (list's own unit, and
// remove's batch), and at most MEDIA_MAX entries per profile per run. Anything left over
// stays in storage, so the report says `error` and the backoff brings it round again —
// a partial run makes progress and never claims completion.
const MEDIA = 'media';
const MEDIA_PAGE = 100, MEDIA_DEPTH = 4, MEDIA_MAX = 5000;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type MediaOutcome = { profile: string; status: string; found: number; removed: number; error?: string };

async function listMedia(profile: string): Promise<{ paths: string[]; incomplete: string | null }> {
  const paths: string[] = [];
  let seen = 0, stopped: string | null = null, skipped: string | null = null;
  const walk = async (prefix: string, depth: number): Promise<void> => {
    for (let offset = 0; !stopped; offset += MEDIA_PAGE) {
      const { data, error } = await sb.storage.from(MEDIA)
        .list(prefix, { limit: MEDIA_PAGE, offset, sortBy: { column: 'name', order: 'asc' } });
      if (error) throw new Error(`list ${prefix}/: ${error.message}`);
      const page = (data ?? []) as { name?: string; id?: string | null }[];
      for (const e of page) {
        const name = String(e?.name ?? '');
        if (!name || name === '.' || name === '..' || name.includes('/')) continue;
        if (++seen > MEDIA_MAX) { stopped = `more than ${MEDIA_MAX} entries`; return; }
        // list() returns a FOLDER as an entry with no id (and no metadata)
        if (e.id == null) {
          // too deep: leave that folder, take everything else, and say so
          if (depth >= MEDIA_DEPTH) { skipped ??= `folders nested deeper than ${MEDIA_DEPTH} at ${prefix}/${name}`; continue; }
          await walk(`${prefix}/${name}`, depth + 1);
          if (stopped) return;
        } else paths.push(`${prefix}/${name}`);
      }
      if (page.length < MEDIA_PAGE) return;
    }
  };
  await walk(profile, 1);
  return { paths, incomplete: stopped ?? skipped };
}

async function cleanMedia(profile: string): Promise<MediaOutcome> {
  // the prefix IS the delete scope: an id that is not a uuid (an empty one lists the
  // bucket root — everyone's photos) is refused before Storage is ever asked
  if (!UUID.test(profile)) return { profile, status: 'refused', found: 0, removed: 0, error: 'not a profile id' };
  let error: string | null = null, found = 0, removed = 0;
  try {
    const { paths, incomplete } = await listMedia(profile);
    const mine = paths.filter((p) => p.startsWith(`${profile}/`));
    found = mine.length;
    for (let i = 0; i < mine.length; i += MEDIA_PAGE) {
      const batch = mine.slice(i, i + MEDIA_PAGE);
      const { data, error: e } = await sb.storage.from(MEDIA).remove(batch);
      if (e) { error ??= `Storage API: ${e.message}`; continue; }
      removed += Array.isArray(data) ? data.length : batch.length;
    }
    if (!error && incomplete) error = `listing incomplete: ${incomplete}`;
  } catch (e) {
    error = `Storage API unreachable: ${e instanceof Error ? e.message : String(e)}`;
  }
  // the server decides, from storage.objects, whether the prefix is empty
  const { data, error: re } = await sb.rpc('_media_cleanup_report', { p_profile: profile, p_error: error });
  if (re) return { profile, status: 'report_failed', found, removed, error: re.message };
  return { profile, status: String(data), found, removed, ...(error ? { error } : {}) };
}

Deno.serve(async (req) => {
  if (!SECRET || req.headers.get('x-cleanup-secret') !== SECRET) {
    console.log('[share-cleanup] refused: missing or wrong x-cleanup-secret');
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401 });
  }
  // abandoned share preparations (a sheet the app never reported back) are reclaimed first,
  // which revokes their never-completed tokens and so queues their cleanup (20261202090000)
  const { error: xe } = await sb.rpc('_expire_share_attempts', { p_ref: null });
  if (xe) {
    console.log('[share-cleanup] could not reclaim abandoned preparations:', xe.message);
    return new Response(JSON.stringify({ error: 'expiry_failed' }), { status: 500 });
  }

  const { data: due, error } = await sb.rpc('_share_cleanup_due', { p_limit: 50 });
  if (error) {
    console.log('[share-cleanup] could not read the queue:', error.message);
    return new Response(JSON.stringify({ error: 'queue_unreadable', detail: error.message }), { status: 500 });
  }
  const tokens = [...new Set((due ?? []) as string[])];
  const results: Outcome[] = [];
  for (const t of tokens) results.push(await cleanOne(t));

  // D395 · then the deleted accounts' photos. Each profile reports on its own; an unread
  // queue is reported, never taken for an empty one (the share half above still stands)
  const { data: gone, error: me } = await sb.rpc('_media_cleanup_due', { p_limit: 20 });
  if (me) console.log('[share-cleanup] could not read the media queue:', me.message);
  const media: MediaOutcome[] = [];
  for (const p of me ? [] : [...new Set((gone ?? []) as string[])]) media.push(await cleanMedia(String(p)));
  const mediaSummary = {
    processed: media.length,
    completed: media.filter((m) => m.status === 'completed').length,
    failed: media.filter((m) => m.status !== 'completed').length,
    objects_removed: media.reduce((n, m) => n + m.removed, 0),
    ...(me ? { error: 'queue_unreadable', detail: me.message } : {}),
  };

  const summary = {
    processed: results.length,
    completed: results.filter((r) => r.status === 'completed').length,
    failed: results.filter((r) => r.status !== 'completed').length,
    results,
    media: { ...mediaSummary, results: media },
  };
  console.log('[share-cleanup]', JSON.stringify({ processed: summary.processed, completed: summary.completed, failed: summary.failed, media: mediaSummary }));
  return new Response(JSON.stringify(summary), { status: me ? 500 : 200, headers: { 'content-type': 'application/json' } });
});
