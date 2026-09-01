// Cup Season — push sender. rev 2026-08-27 (D104 wave 7: routed APNs)
// Invoked by Database Webhooks:
//   - public.posts INSERT           -> league board fan-out (event posts too)
//   - public.push_nudges INSERT     -> one row = one recipient (nudge/invite/request/rsvp)
//   - public.friendships INSERT/UPDATE -> friend-request EMAIL + accept ping
//     (the request PUSH rides push_nudges since D104 — see friend_request())
// Auth: shared secret header (x-push-secret); deploy with --no-verify-jwt.
//
// Secrets required (supabase secrets set):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT, PUSH_WEBHOOK_SECRET
// Optional (enables friend-request EMAIL alongside web push):
//   BREVO_API_KEY  — Brevo (Sendinblue) transactional API key. Sender below
//                    must be an authorised sender/domain in your Brevo account.
// Optional (lights up APNs — docs/ios/push-contract.md §8):
//   APNS_P8, APNS_KEY_ID, APNS_TEAM_ID (+ APNS_TOPIC, APNS_SANDBOX=1)
//
// Two rails, one voice. Web push keeps its payload EXACTLY {title, body, url:'/'}.
// APNs carries the contract's routed payload (docs/ios/push-contract.md §1):
// aps.alert (the same clamped strings), aps.sound, aps.thread-id, aps.badge
// (the recipient's actionable count), aps.category only when actionable, and
// the `cs` object with `v:1`, `kind`, and only the ids that exist for that kind.

import { createClient } from 'npm:@supabase/supabase-js@2';
import webpush from 'npm:web-push@3';

const sb = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

webpush.setVapidDetails(
  Deno.env.get('VAPID_SUBJECT') ?? 'mailto:hello@cupseason.app',
  Deno.env.get('VAPID_PUBLIC_KEY')!,
  Deno.env.get('VAPID_PRIVATE_KEY')!,
);

/* ---- lock-screen copy (D77) -----------------------------------------------
 * ONE budget, declared once. It used to be an inline `.slice(0, 140)` in the
 * web-push builder AND a second one in the APNs builder, so a fix to either
 * missed the other — and a hard slice cuts mid-word, which on the old feed-row
 * bodies meant cutting through somebody's name.
 */
const TITLE_MAX = 80;
const BODY_MAX = 140;

/* truncate on a word boundary and say so, rather than stopping mid-name */
function clamp(s: string, max: number): string {
  const t = String(s ?? '').replace(/\s+/g, ' ').trim();
  if (t.length <= max) return t;
  const cut = t.slice(0, max - 1);
  const sp = cut.lastIndexOf(' ');
  return (sp > max * 0.6 ? cut.slice(0, sp) : cut).trimEnd() + '…';
}

const firstName = (n: string | null | undefined) =>
  String(n ?? '').trim().split(/\s+/)[0] || 'Someone';

/* Since the D77 SQL pass, a board row is an authored, result-first sentence
 * ("Jerecho posted 92 at Encanto GC."). So the headline is already written —
 * it is the first sentence. Split there: the result becomes the bold line, the
 * league or event name becomes the context underneath. This is why no
 * push_title/push_body columns are needed: the generators already say the
 * right thing first, and forwarding the whole row was what buried it.
 */
/* One entry point for both cases: an authored title when the generator gave us
   one (settlements — see posts.push_title), otherwise the first-sentence split
   below. Kept together so no emit site can use one and forget the other. */
function headline(authored: unknown, body: unknown, context: string): { title: string; body: string } {
  const a = String(authored ?? '').replace(/\s+/g, ' ').trim();
  if (a) return { title: clamp(a, TITLE_MAX), body: clamp(context, BODY_MAX) };
  return split(String(body ?? ''), context);
}

function split(body: string, context: string): { title: string; body: string } {
  const t = String(body ?? '').replace(/\s+/g, ' ').trim();
  if (!t) return { title: '', body: '' };                 /* caller skips */
  const m = t.match(/^(.{1,90}?[.!?])(?:\s|$)/);
  const head = (m ? m[1] : t).replace(/[.]+$/, '');
  const rest = m ? t.slice(m[1].length).trim() : '';
  return {
    title: clamp(head, TITLE_MAX),
    body: clamp(rest ? `${context} · ${rest}` : context, BODY_MAX),
  };
}

/* every exit is named, so a misroute is distinguishable from a no-op — the
 * D68 landmine: this function answered a bare `ok` on six different paths, so
 * a webhook pointed at the WRONG function logged HTTP 200 `ok` and looked
 * exactly like success while the intended function showed zero invocations */
const reply = (reason: string, extra: Record<string, unknown> = {}) => {
  console.log(`[push] exit reason=${reason} ${JSON.stringify(extra)}`);
  return new Response(JSON.stringify({ ok: reason === 'sent', reason, ...extra }), {
    status: reason === 'no-record' ? 400 : 200,
    headers: { 'content-type': 'application/json' },
  });
};

// ---- the route (D104 · docs/ios/push-contract.md §1–§3) --------------------
// What the phone needs to land on the right screen. Web push never sees it.
type CsKind =
  | 'round' | 'chat' | 'announce' | 'moment' | 'system' | 'settlement' | 'live_open'
  | 'nudge' | 'invite' | 'request' | 'rsvp' | 'event';
const CS_ID_KEYS = [
  'league_id', 'post_id', 'round_id', 'live_round_id', 'event_id',
  'profile_id', 'scheduled_round_id', 'request_id', 'invite_id',
] as const;
type CsIdKey = typeof CS_ID_KEYS[number];
type Cs = { v: 1; kind: CsKind } & Partial<Record<CsIdKey, string>>;
type Category = 'CS_REQUEST' | 'CS_RSVP' | 'CS_INVITE';
type Route = {
  cs: Cs;
  /* thread-id groups a league's / an event's notifications; personal ones
     (requests, invites, nudges) use 'you' — contract §1 */
  thread: string;
  /* only when the lock screen can answer it — contract §3 */
  category?: Category;
  /* apns-collapse-id: the post / nudge id, so a webhook retry does not double */
  collapseId?: string;
};

/* only the ids that exist for that kind are present (contract §1) */
function route(
  kind: CsKind,
  ids: Partial<Record<CsIdKey, unknown>>,
  opts: { thread?: string; category?: Category; collapseId?: string } = {},
): Route {
  const cs: Cs = { v: 1, kind };
  for (const k of CS_ID_KEYS) {
    const v = ids[k];
    if (v !== undefined && v !== null && v !== '') cs[k] = String(v);
  }
  return {
    cs,
    thread: opts.thread ?? cs.league_id ?? cs.event_id ?? 'you',
    category: opts.category,
    collapseId: opts.collapseId,
  };
}

/* a `system` board row that settled a live round IS the settlement (D92:
   posts.live_round_id) — it routes to the scorecard, not the board */
function postKind(kind: unknown, liveRoundId: unknown): CsKind {
  const k = String(kind ?? '');
  if (k === 'system' && liveRoundId) return 'settlement';
  if (k === 'round' || k === 'chat' || k === 'announce' || k === 'moment' || k === 'system') return k;
  return 'system';
}

/* the people who muted this author — contract §5.3. One query, a Set. */
async function mutersOf(authorProfileId: string | null | undefined): Promise<Set<string>> {
  if (!authorProfileId) return new Set();
  const { data, error } = await sb.from('mutes').select('muter').eq('muted', authorProfileId);
  if (error) console.error(`[push] mutes read failed msg=${error.message}`);
  return new Set((data ?? []).map((m) => String(m.muter)));
}

/* the recipient's ACTIONABLE count — contract §4. One definition, in SQL
   (actionable_count_of, service_role only), so the badge the server stamps
   and the number the phone asks for (my_actionable_count) can never drift.
   Undefined = unavailable (e.g. function deployed before the migration):
   the push still goes, without a badge, and says so in the log. */
async function actionableCount(profileId: string): Promise<number | undefined> {
  const { data, error } = await sb.rpc('actionable_count_of', { p_profile: profileId });
  if (error) { console.log(`[apns] badge unavailable profile=${profileId} msg=${error.message}`); return undefined; }
  const n = Number(data);
  return Number.isFinite(n) ? n : undefined;
}

async function sendTo(profileIds: string[], title: string, body: string, r: Route) {
  if (!profileIds.length) { console.log(`[push] kind=${r.cs.kind} no recipients`); return; }
  /* clamp ONCE, here, so web push and APNs below carry identical text */
  title = clamp(title, TITLE_MAX);
  body = clamp(body, BODY_MAX);

  const { data: subs } = await sb
    .from('push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('profile_id', profileIds);
  if (!subs?.length) {
    console.log(`[push] kind=${r.cs.kind} no web subs for recipients`);
  } else {
    /* url stays '/' deliberately: the web client routes nothing per-post, and a
       link that lands somewhere wrong is worse than one that lands home. The
       routed payload is APNs-only (below). */
    const payload = JSON.stringify({ title, body, url: '/' });
    const dead: string[] = [];
    let sent = 0;
    await Promise.all(subs.map(async (s) => {
      try {
        await webpush.sendNotification(
          { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
          payload,
        );
        sent++;
      } catch (e) {
        const code = (e as { statusCode?: number })?.statusCode;
        console.error(`[push] send failed code=${code} body=${(e as { body?: string })?.body ?? ''} msg=${(e as Error)?.message ?? e}`);
        if (code === 404 || code === 410) dead.push(s.id); // subscription expired
      }
    }));
    if (dead.length) await sb.from('push_subscriptions').delete().in('id', dead);
    console.log(`[push] kind=${r.cs.kind} recipients=${profileIds.length} web sent=${sent} pruned=${dead.length}`);
  }

  await sendApns(profileIds, title, body, r);
}

// ---- APNs (iOS arc W5 · routed since D104) ----------------------------------
// Native device tokens land in device_tokens (register_device_token RPC) and
// get APNs here. Entirely env-gated: with no APNS_* secrets this is a silent
// no-op, so the branch ships dormant and lights up when the key arrives.
// Secrets: APNS_P8 (key file contents), APNS_KEY_ID, APNS_TEAM_ID.
// Optional: APNS_TOPIC (defaults to the bundle id), APNS_SANDBOX=1 for dev.
let apnsJwt: { token: string; at: number } | null = null;
async function apnsToken(): Promise<string | null> {
  const p8 = Deno.env.get('APNS_P8'), kid = Deno.env.get('APNS_KEY_ID'), team = Deno.env.get('APNS_TEAM_ID');
  if (!p8 || !kid || !team) return null;
  if (apnsJwt && Date.now() - apnsJwt.at < 45 * 60_000) return apnsJwt.token;
  const pem = p8.replace(/-----[^-]+-----|\s/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const b64 = (o: unknown) => btoa(JSON.stringify(o)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const input = `${b64({ alg: 'ES256', kid })}.${b64({ iss: team, iat: Math.floor(Date.now() / 1000) })}`;
  const sig = new Uint8Array(await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(input)));
  const sigB64 = btoa(String.fromCharCode(...sig)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  apnsJwt = { token: `${input}.${sigB64}`, at: Date.now() };
  return apnsJwt.token;
}

/* the contract's payload (§1), built per recipient because the badge is theirs */
function apnsPayload(title: string, body: string, r: Route, badge: number | undefined): string {
  const aps: Record<string, unknown> = {
    alert: { title, body },
    sound: 'default',
    'thread-id': r.thread,
  };
  if (badge !== undefined) aps.badge = badge;
  if (r.category) aps.category = r.category;
  return JSON.stringify({ aps, cs: r.cs });
}

async function sendApns(profileIds: string[], title: string, body: string, r: Route) {
  const jwt = await apnsToken();
  if (!jwt) return; // dormant until the APNS_* secrets exist
  const { data: toks } = await sb.from('device_tokens')
    .select('token, profile_id, platform').in('profile_id', profileIds);
  if (!toks?.length) { console.log(`[apns] kind=${r.cs.kind} no device tokens`); return; }
  /* each token goes to ITS host: a Debug build registers `ios-sandbox`, a
     TestFlight/App Store build registers `ios`. APNS_SANDBOX=1 decides only the
     pre-20260828010000 rows, which carry no usable platform — a row that SAYS
     which environment it came from is believed over the env var. It used to
     win globally, which meant one forgotten secret sent every TestFlight
     token to the sandbox host, where APNs answers BadDeviceToken. */
  const SANDBOX = 'https://api.sandbox.push.apple.com', PROD = 'https://api.push.apple.com';
  const forceSandbox = !!Deno.env.get('APNS_SANDBOX');
  const hostFor = (platform?: string | null) =>
    platform === 'ios-sandbox' ? SANDBOX : platform === 'ios' ? PROD : (forceSandbox ? SANDBOX : PROD);
  const topic = Deno.env.get('APNS_TOPIC') ?? 'app.cupseason.ios';

  /* the badge is the recipient's actionable count at send time (§4) — one
     count per distinct profile, not per token; ≤ a dozen recipients per post */
  const owners = [...new Set(toks.map((t) => String(t.profile_id)))];
  const badges = new Map<string, number | undefined>();
  await Promise.all(owners.map(async (id) => badges.set(id, await actionableCount(id))));

  const headers: Record<string, string> = {
    authorization: `bearer ${jwt}`,
    'apns-topic': topic,
    'apns-push-type': 'alert',
  };
  /* a webhook retry re-sends the same row; the same collapse id folds it */
  if (r.collapseId) headers['apns-collapse-id'] = String(r.collapseId).slice(0, 64);

  /* APNs answers with a JSON `reason`, and only ONE of them means the device is
     gone. `BadDeviceToken` is the ambiguous one: malformed, or a perfectly good
     token posted to the wrong environment — which is what a build-type change
     or a stale APNS_SANDBOX produces. Deleting on it (as this did) turned a
     routing mistake into a silently unregistered tester who would not get push
     again until they relaunched the app. Retry the other host instead, and
     correct the row when that host takes it. */
  const dead: string[] = [];
  const rehomed: { token: string; platform: string }[] = [];
  let sent = 0, misrouted = 0;
  const reasonOf = (txt: string) => { try { return String(JSON.parse(txt)?.reason ?? ''); } catch { return ''; } };
  await Promise.all(toks.map(async (t) => {
    /* already clamped by sendTo — no second, divergent budget here */
    const payload = apnsPayload(title, body, r, badges.get(String(t.profile_id)));
    const post = (host: string) => fetch(`${host}/3/device/${t.token}`, { method: 'POST', headers, body: payload });
    const host = hostFor(t.platform);
    try {
      const res = await post(host);
      if (res.ok) { sent++; return; }
      const txt = await res.text().catch(() => '');
      const reason = reasonOf(txt) || txt.slice(0, 60);
      if (res.status === 410 || reason === 'Unregistered') {
        console.log(`[apns] gone reason=${reason || res.status} — pruning`);
        dead.push(t.token); return;
      }
      if (reason === 'BadDeviceToken') {
        const alt = host === SANDBOX ? PROD : SANDBOX;
        const res2 = await post(alt);
        if (res2.ok) {
          sent++; misrouted++;
          rehomed.push({ token: t.token, platform: alt === SANDBOX ? 'ios-sandbox' : 'ios' });
          console.warn(`[apns] MISROUTED platform=${t.platform ?? 'null'} — delivered on ${alt}, row corrected`);
          return;
        }
        const r2 = reasonOf(await res2.text().catch(() => ''));
        /* refused by BOTH hosts: the token really is malformed */
        if (res2.status === 410 || r2 === 'Unregistered' || r2 === 'BadDeviceToken') dead.push(t.token);
        console.error(`[apns] bad on both hosts status=${res2.status} reason=${r2}`);
        return;
      }
      /* 403 InvalidProviderToken, 429, 5xx: our problem or a transient one —
         never the device's, so the row stays and the next post retries. */
      console.error(`[apns] status=${res.status} reason=${reason}`);
    } catch (e) {
      console.error(`[apns] failed msg=${(e as Error)?.message ?? e}`);
    }
  }));
  if (rehomed.length) {
    await Promise.all(rehomed.map((x) =>
      sb.from('device_tokens').update({ platform: x.platform }).eq('token', x.token)));
  }
  if (dead.length) await sb.from('device_tokens').delete().in('token', dead);
  const sandboxN = toks.filter((t) => hostFor(t.platform) === SANDBOX).length;
  console.log(`[apns] kind=${r.cs.kind} thread=${r.thread} category=${r.category ?? '-'} tokens=${toks.length} sandbox=${sandboxN} sent=${sent} misrouted=${misrouted} pruned=${dead.length}`);
}

// Transactional email via Brevo. No-op (logs and returns) when BREVO_API_KEY
// is unset, so email is purely additive — push never depends on it.
async function sendEmail(toEmail: string, toName: string, subject: string, html: string) {
  const key = Deno.env.get('BREVO_API_KEY');
  if (!key) { console.log('[email] BREVO_API_KEY unset — skipping'); return; }
  if (!toEmail || toEmail.endsWith('@cupseason.invalid')) { console.log('[email] no valid recipient'); return; }
  try {
    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: { 'api-key': key, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({
        // Must be an authorised sender in Brevo — default to the address your
        // auth emails already use; override with the BREVO_SENDER secret.
        sender: { name: 'Cup Season', email: Deno.env.get('BREVO_SENDER') ?? 'hello@cupseason.app' },
        to: [{ email: toEmail, name: toName || undefined }],
        subject,
        htmlContent: html,
      }),
    });
    if (res.status >= 300) {
      const body = await res.text().catch(() => '');
      console.log(`[email] status=${res.status} body=${body.slice(0, 300)}`);
    } else {
      console.log(`[email] status=${res.status}`);
    }
  } catch (e) {
    console.error(`[email] failed msg=${(e as Error)?.message ?? e}`);
  }
}

/* the handle in parentheses was plumbing leaking into a sentence, and the full
   legal name is not how a friend refers to a friend (D77) */
function friendRequestEmail(toName: string, fromName: string) {
  const greeting = toName ? `Hi ${firstName(toName)},` : 'Hi,';
  const who = firstName(fromName);
  return `<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;color:#1a2620">
    <p style="font-size:16px;line-height:1.5">${greeting}</p>
    <p style="font-size:16px;line-height:1.5"><strong>${who}</strong> wants in your crew on Cup Season.</p>
    <p style="font-size:16px;line-height:1.5">Accept and their rounds land in your feed, all season.</p>
    <p style="margin:24px 0">
      <a href="https://cupseason.app" style="background:#E9BE62;color:#1c1503;text-decoration:none;font-weight:600;padding:12px 22px;border-radius:10px;display:inline-block">Open Cup Season</a>
    </p>
    <p style="font-size:12px;color:#8c9992;line-height:1.5">You're getting this because someone added you on Cup Season. Manage notifications in your Tour Card.</p>
  </div>`;
}

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }

  const { type, table, record, old_record } = await req.json().catch(() => ({}));
  /* log EVERY invocation before branching: a webhook created against the wrong
     function is otherwise invisible (D68 — it cost several round trips) */
  console.log(`[push] invoked table=${table ?? '?'} type=${type ?? '?'} kind=${record?.kind ?? '-'}`);
  if (!record) return reply('no-record');

  if (table === 'friendships') {
    const who = async (id: string) => {
      const { data } = await sb.from('profiles')
        .select('display_name, handle, email').eq('id', id).maybeSingle();
      return data;
    };
    /* the title was the literal app name on both of these — which the OS
       already prints above every notification next to the icon, so the bold
       line carried nothing. The news goes in the title now (D77). */
    if (type === 'INSERT' && record.status === 'pending') {
      /* D104: the request PUSH now rides push_nudges (kind='request', inserted
         by friend_request() itself) so it carries request_id + profile_id and
         a CS_REQUEST category. This branch keeps the EMAIL only — sending the
         push here too would double it wherever this webhook is wired. */
      const [p, a] = await Promise.all([who(record.requester), who(record.addressee)]);
      const from = firstName(p?.display_name ?? 'A golfer');
      console.log('[push] kind=friend-request channel=email (push rides push_nudges since D104)');
      // Requests only (pilot decision) — email the person who was added.
      await sendEmail(
        a?.email ?? '', a?.display_name ?? '',
        `${from} wants in your crew`,
        friendRequestEmail(a?.display_name ?? '', p?.display_name ?? 'A golfer'),
      );
      return reply('sent', { kind: 'friend-request', channel: 'email' });
    } else if (type === 'UPDATE' && record.status === 'accepted' && old_record?.status === 'pending') {
      const p = await who(record.addressee);
      console.log('[push] kind=friend-accept');
      /* not actionable (no category); lands Requests via profile_id */
      await sendTo([record.requester], `${firstName(p?.display_name ?? 'Your buddy')} is in your crew`,
        "You'll see their rounds now",
        route('request', { request_id: record.id, profile_id: record.addressee },
          { thread: 'you', collapseId: record.id }));
      return reply('sent', { kind: 'friend-accept' });
    }
    return reply('friendship-no-op', { type, status: record.status });
  }

  // one row = one recipient: the Ryder taunt (D86 tee-sheet call too), and
  // since D104 the routed personal kinds — invite / request / rsvp
  if (table === 'push_nudges') {
    /* the one genuinely personalised notification on the surface — one row per
       recipient, title and body authored by the generator. Nothing to rewrite;
       it only needed the empty-body guard the others needed. */
    const nb = String(record.body ?? '').trim();
    const nk = String(record.kind ?? 'nudge');
    if (!nb) return reply('empty-body', { kind: nk, nudge: record.id });
    const pl = (record.payload && typeof record.payload === 'object' ? record.payload : {}) as Partial<Record<CsIdKey, unknown>>;

    /* personal kinds thread as 'you' (contract §1); categories per §3 */
    let r: Route;
    if (nk === 'invite') {
      r = route('invite', { invite_id: pl.invite_id, league_id: pl.league_id, event_id: pl.event_id },
        { thread: 'you', category: 'CS_INVITE', collapseId: record.id });
    } else if (nk === 'request') {
      r = route('request', { request_id: pl.request_id, profile_id: pl.profile_id },
        { thread: 'you', category: 'CS_REQUEST', collapseId: record.id });
    } else if (nk === 'rsvp') {
      r = route('rsvp', { scheduled_round_id: pl.scheduled_round_id, profile_id: pl.profile_id },
        { thread: 'you', category: 'CS_RSVP', collapseId: record.id });
    } else {
      /* the Ryder taunt / the live-round call: ids only when the inserter
         wrote a payload (today's inserters write none — those land Home) */
      r = route('nudge', { event_id: pl.event_id, live_round_id: pl.live_round_id, league_id: pl.league_id },
        { thread: 'you', collapseId: record.id });
    }

    /* a muted requester / host does not ring the muter (§5.3) — the author
       is whoever the payload names */
    const muters = await mutersOf(pl.profile_id ? String(pl.profile_id) : null);
    if (muters.has(String(record.profile_id))) {
      return reply('muted', { kind: nk, nudge: record.id });
    }
    console.log(`[push] kind=${nk} recipients=1`);
    await sendTo([record.profile_id], String(record.title ?? 'The Ryder'), nb, r);
    return reply('sent', { kind: nk });
  }

  // event board posts (the Ryder): fan to the event's players
  if (!record.league_id) {
    if (!record.event_id) return reply('no-league-or-event', { post: record.id });
    const [{ data: evt }, { data: eps }] = await Promise.all([
      sb.from('events').select('name').eq('id', record.event_id).maybeSingle(),
      sb.from('event_players').select('profile_id').eq('event_id', record.event_id),
    ]);
    /* event rows carry no author column the roster can be filtered on, so
       "never the author" and mutes cannot apply here — as today */
    const recipients = (eps ?? []).map((e) => e.profile_id);
    /* the event name was the title and the whole feed row was the body; the
       row's own first sentence is the headline (D77) and the event name is
       the context under it */
    const n = headline(record.push_title, record.body, evt?.name ?? 'The Ryder');
    if (!n.title) return reply('empty-body', { kind: record.kind, post: record.id });
    console.log(`[push] kind=${record.kind} event recipients=${recipients.length}`);
    await sendTo(recipients, n.title, n.body,
      route('event', { event_id: record.event_id, post_id: record.id }, { collapseId: record.id }));
    return reply('sent', { kind: record.kind, recipients: recipients.length });
  }

  const [{ data: lg }, { data: members }] = await Promise.all([
    sb.from('leagues').select('name, notify_system').eq('id', record.league_id).maybeSingle(),
    sb.from('league_members')
      .select('id, profile_id, profiles(notify_chat, notify_rounds)')
      .eq('league_id', record.league_id),
  ]);

  const kind = postKind(record.kind, record.live_round_id);
  /* the Pro's curation (§5.4): plain `system` rows (floors, closes, joins)
     stay quiet when notify_system is off. A settlement is the players' own
     result and is not `system` for this purpose. Column absent (deploy skew:
     function before migration) reads as undefined → on. */
  if (kind === 'system' && lg?.notify_system === false) {
    return reply('curated-off', { kind: 'system', post: record.id, league: record.league_id });
  }

  // curated push: chat -> notify_chat, round -> notify_rounds, everything else
  // (moment / announce / system / settlement) always delivers.
  /* PostgREST returns the to-one `profiles` embed as an object; supabase-js
     without a generated schema types it as an array — normalise either */
  type Prefs = { notify_chat?: boolean; notify_rounds?: boolean } | null | undefined;
  const prefsOf = (p: unknown): Prefs => (Array.isArray(p) ? p[0] : p) as Prefs;
  const wants = (raw: unknown) => {
    const p = prefsOf(raw);
    if (record.kind === 'chat') return p?.notify_chat ?? true;
    if (record.kind === 'round') return p?.notify_rounds ?? true;
    return true;
  };
  /* the author's profile, for mutes: posts.member_id is a league_members id,
     and the roster we already hold maps it */
  const authorProfile = (members ?? []).find((m) => m.id === record.member_id)?.profile_id ?? null;
  const muters = await mutersOf(authorProfile);
  const recipients = (members ?? [])
    .filter((m) => m.id !== record.member_id) // never ping the author
    .filter((m) => wants(m.profiles))
    .filter((m) => !muters.has(String(m.profile_id))) // §5.3: muted the author
    .map((m) => m.profile_id);
  /* the highest-volume notification in the product, and it had no copy of its
     own: the league name was the title and the whole feed row was the body.
     'Something happened on the board' was worse than silence — it woke a phone
     to say nothing — so an empty body is now a skip, not a filler. */
  /* a settlement carries an authored push_title (20260727240000) — the client's
     short `share` string, first names and all. Prefer it: deriving from the
     feed row is right for every other kind, but a 2v2 board row keeps FULL
     names by design and a lock screen may cut before the score. */
  const n = headline(record.push_title, record.body, lg?.name ?? 'Cup Season');
  if (!n.title) return reply('empty-body', { kind: record.kind, post: record.id });
  console.log(`[push] kind=${record.kind} cs=${kind} recipients=${recipients.length} muted=${muters.size ? (members ?? []).filter((m) => muters.has(String(m.profile_id))).length : 0}`);
  /* live_open is a realtime broadcast on the league channel today, not a
     post — it never reaches this function and is left as it is (D104) */
  await sendTo(recipients, n.title, n.body,
    route(kind, {
      league_id: record.league_id, post_id: record.id,
      round_id: record.round_id, live_round_id: record.live_round_id,
    }, { collapseId: record.id }));
  return reply('sent', { kind: record.kind, recipients: recipients.length });
});
