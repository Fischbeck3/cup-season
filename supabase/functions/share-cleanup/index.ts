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
// D403 · and a TAKEN-DOWN photo's file (public.media_takedowns, queued by takedown_photo):
// moved out of `media` into the private `moderation-hold` bucket, which kills every URL
// minted before the takedown (a signed URL is honoured on its signature, not through
// RLS, so hiding the row is not enough), or removed outright when the move fails —
// removal beats retention. _takedown_cleanup_report re-reads storage.objects before it
// records `removed`, and backs off on failure. Kept evidence is deleted after 90 days.
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
  // D400/D396: the same account queue also owns their league uploads.
  // Names come only from the definer's owner-scoped read, never a webhook body.
  try {
    const { data: paths, error: readError } = await sb.rpc('_league_media_cleanup_paths', { p_profile: profile });
    if (readError) error ??= 'League media read: ' + readError.message;
    else {
      const leaguePaths = (paths ?? []) as string[];
      found += leaguePaths.length;
      for (let i = 0; i < leaguePaths.length; i += MEDIA_PAGE) {
        const batch = leaguePaths.slice(i, i + MEDIA_PAGE);
        const { data, error: e } = await sb.storage.from('league-media').remove(batch);
        if (e) { error ??= 'League media Storage API: ' + e.message; continue; }
        removed += Array.isArray(data) ? data.length : batch.length;
      }
    }
  } catch (e) {
    error ??= 'League media unreachable: ' + (e instanceof Error ? e.message : String(e));
  }
  // the server decides, from storage.objects, whether all owned photos are gone
  const { data, error: re } = await sb.rpc('_media_cleanup_report', { p_profile: profile, p_error: error });
  if (re) return { profile, status: 'report_failed', found, removed, error: re.message };
  return { profile, status: String(data), found, removed, ...(error ? { error } : {}) };
}

// ---- D403 · a taken-down photo's file ---------------------------------------------------
const HOLD = 'moderation-hold';
type TakedownRow = { id: string; phase: 'remove' | 'purge'; bucket: string; path: string; hold_path: string | null };
type TakedownOutcome = { id: string; phase: string; status: string; error?: string };

async function takeDown(row: TakedownRow): Promise<TakedownOutcome> {
  let error: string | null = null;
  try {
    if (row.phase === 'remove') {
      // only the bucket this queue was built for; the path comes from the definer's queue
      if (row.bucket !== 'media' || !row.path || row.path.includes('..')) throw new Error('not a media path');
      let moved = false;
      if (row.hold_path) {
        const { error: me } = await sb.storage.from(row.bucket).move(row.path, row.hold_path, { destinationBucket: HOLD });
        if (me) error = `move to ${HOLD}: ${me.message}`;
        else moved = true;
      }
      if (!moved) {
        // removal beats retention: the published file goes even if the evidence cannot be kept
        const { error: re } = await sb.storage.from(row.bucket).remove([row.path]);
        if (re) error = `${error ? error + '; ' : ''}remove: ${re.message}`;
      }
    } else {
      if (!row.hold_path) throw new Error('nothing kept to purge');
      const { error: pe } = await sb.storage.from(HOLD).remove([row.hold_path]);
      if (pe) error = `purge: ${pe.message}`;
    }
  } catch (e) {
    error = `Storage API unreachable: ${e instanceof Error ? e.message : String(e)}`;
  }
  // the server decides, from storage.objects, whether the file is gone
  const { data, error: re } = await sb.rpc('_takedown_cleanup_report', { p_id: row.id, p_phase: row.phase, p_error: error });
  if (re) return { id: row.id, phase: row.phase, status: 'report_failed', error: re.message };
  return { id: row.id, phase: row.phase, status: String(data), ...(error ? { error } : {}) };
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

  // D403 · then taken-down photos' files. Taken first-come by next_try; an unread queue is
  // reported (status 500), never taken for an empty one.
  const { data: downs, error: dueErr } = await sb.rpc('_takedown_cleanup_due', { p_limit: 20 });
  // deploy skew: this function may go out before its migration; a queue that does not
  // exist yet is not an outage (and is named in the summary, never read as empty-and-healthy)
  const notYet = !!dueErr && /could not find the function|pgrst202|schema cache/i.test(`${dueErr.code ?? ''} ${dueErr.message ?? ''}`);
  const te = notYet ? null : dueErr;
  if (te) console.log('[share-cleanup] could not read the takedown queue:', te.message);
  const takedowns: TakedownOutcome[] = [];
  for (const row of te ? [] : ((downs ?? []) as TakedownRow[])) takedowns.push(await takeDown(row));
  const takedownSummary = {
    processed: takedowns.length,
    removed: takedowns.filter((t) => t.status === 'removed').length,
    purged: takedowns.filter((t) => t.status === 'purged').length,
    failed: takedowns.filter((t) => t.status !== 'removed' && t.status !== 'purged').length,
    ...(te ? { error: 'queue_unreadable', detail: te.message } : {}),
    ...(notYet ? { skipped: 'takedown queue not deployed' } : {}),
  };

  const summary = {
    processed: results.length,
    completed: results.filter((r) => r.status === 'completed').length,
    failed: results.filter((r) => r.status !== 'completed').length,
    results,
    media: { ...mediaSummary, results: media },
    takedowns: { ...takedownSummary, results: takedowns },
  };
  console.log('[share-cleanup]', JSON.stringify({ processed: summary.processed, completed: summary.completed, failed: summary.failed, media: mediaSummary, takedowns: takedownSummary }));
  return new Response(JSON.stringify(summary), { status: me || te ? 500 : 200, headers: { 'content-type': 'application/json' } });
});
