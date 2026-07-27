// Cup Season — push sender. rev 2026-07-14 (friend-request email)
// Invoked by Database Webhooks:
//   - public.posts INSERT           -> league board fan-out
//   - public.friendships INSERT/UPDATE -> friend request / accept pings
// Auth: shared secret header (x-push-secret); deploy with --no-verify-jwt.
//
// Secrets required (supabase secrets set):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT, PUSH_WEBHOOK_SECRET
// Optional (enables friend-request EMAIL alongside web push):
//   BREVO_API_KEY  — Brevo (Sendinblue) transactional API key. Sender below
//                    must be an authorised sender/domain in your Brevo account.

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

async function sendTo(profileIds: string[], title: string, body: string) {
  if (!profileIds.length) return;
  const { data: subs } = await sb
    .from('push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('profile_id', profileIds);
  if (!subs?.length) { console.log('[push] no subs for recipients'); return; }

  /* clamp ONCE, here, so web push and APNs below carry identical text */
  title = clamp(title, TITLE_MAX);
  body = clamp(body, BODY_MAX);
  /* url stays '/' deliberately: nothing routes a per-post deep link yet, and a
     link that lands somewhere wrong is worse than one that lands home */
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
  console.log(`[push] sent=${sent} pruned=${dead.length}`);

  await sendApns(profileIds, title, body);
}

// ---- APNs (iOS arc W5) ------------------------------------------------------
// The Capacitor wrapper's WKWebView can't receive web push; native device
// tokens land in device_tokens (register_device_token RPC) and get APNs here.
// Entirely env-gated: with no APNS_* secrets this is a silent no-op, so the
// branch ships dormant and lights up when the Mac-phase key arrives.
// Secrets (Mac phase): APNS_P8 (key file contents), APNS_KEY_ID, APNS_TEAM_ID.
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
async function sendApns(profileIds: string[], title: string, body: string) {
  const jwt = await apnsToken();
  if (!jwt) return; // dormant until the APNS_* secrets exist
  const { data: toks } = await sb.from('device_tokens')
    .select('token').in('profile_id', profileIds);
  if (!toks?.length) return;
  const host = Deno.env.get('APNS_SANDBOX') ? 'https://api.sandbox.push.apple.com' : 'https://api.push.apple.com';
  const topic = Deno.env.get('APNS_TOPIC') ?? 'app.cupseason.ios';
  /* already clamped by sendTo — no second, divergent budget here */
  const payload = JSON.stringify({ aps: { alert: { title, body }, sound: 'default' } });
  const dead: string[] = [];
  let sent = 0;
  await Promise.all(toks.map(async (t) => {
    try {
      const res = await fetch(`${host}/3/device/${t.token}`, {
        method: 'POST',
        headers: { authorization: `bearer ${jwt}`, 'apns-topic': topic, 'apns-push-type': 'alert' },
        body: payload,
      });
      if (res.ok) { sent++; return; }
      const txt = await res.text().catch(() => '');
      console.error(`[apns] status=${res.status} body=${txt.slice(0, 120)}`);
      if (res.status === 410 || txt.includes('BadDeviceToken') || txt.includes('Unregistered')) dead.push(t.token);
    } catch (e) {
      console.error(`[apns] failed msg=${(e as Error)?.message ?? e}`);
    }
  }));
  if (dead.length) await sb.from('device_tokens').delete().in('token', dead);
  if (sent || dead.length) console.log(`[apns] sent=${sent} pruned=${dead.length}`);
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
      const [p, a] = await Promise.all([who(record.requester), who(record.addressee)]);
      const from = firstName(p?.display_name ?? 'A golfer');
      console.log('[push] kind=friend-request');
      await sendTo([record.addressee], `${from} wants in your crew`, 'Tap to accept');
      // Requests only (pilot decision) — email the person who was added.
      await sendEmail(
        a?.email ?? '', a?.display_name ?? '',
        `${from} wants in your crew`,
        friendRequestEmail(a?.display_name ?? '', p?.display_name ?? 'A golfer'),
      );
      return reply('sent', { kind: 'friend-request' });
    } else if (type === 'UPDATE' && record.status === 'accepted' && old_record?.status === 'pending') {
      const p = await who(record.addressee);
      console.log('[push] kind=friend-accept');
      await sendTo([record.requester], `${firstName(p?.display_name ?? 'Your buddy')} is in your crew`,
        "You'll see their rounds now");
      return reply('sent', { kind: 'friend-accept' });
    }
    return reply('friendship-no-op', { type, status: record.status });
  }

  // opt-in duel taunts (the Ryder, batch-3 #17): one row = one recipient
  if (table === 'push_nudges') {
    /* the one genuinely personalised notification on the surface — one row per
       recipient, title and body authored by the generator. Nothing to rewrite;
       it only needed the empty-body guard the others needed. */
    const nb = String(record.body ?? '').trim();
    if (!nb) return reply('empty-body', { kind: 'nudge' });
    console.log('[push] kind=nudge');
    await sendTo([record.profile_id], String(record.title ?? 'The Ryder'), nb);
    return reply('sent', { kind: 'nudge' });
  }

  // event board posts (the Ryder): fan to the event's players
  if (!record.league_id) {
    if (!record.event_id) return reply('no-league-or-event', { post: record.id });
    const [{ data: evt }, { data: eps }] = await Promise.all([
      sb.from('events').select('name').eq('id', record.event_id).maybeSingle(),
      sb.from('event_players').select('profile_id').eq('event_id', record.event_id),
    ]);
    const recipients = (eps ?? []).map((e) => e.profile_id);
    /* the event name was the title and the whole feed row was the body; the
       row's own first sentence is the headline (D77) and the event name is
       the context under it */
    const n = headline(record.push_title, record.body, evt?.name ?? 'The Ryder');
    if (!n.title) return reply('empty-body', { kind: record.kind, post: record.id });
    console.log(`[push] kind=${record.kind} event recipients=${recipients.length}`);
    await sendTo(recipients, n.title, n.body);
    return reply('sent', { kind: record.kind, recipients: recipients.length });
  }

  const [{ data: lg }, { data: members }] = await Promise.all([
    sb.from('leagues').select('name').eq('id', record.league_id).maybeSingle(),
    sb.from('league_members')
      .select('id, profile_id, profiles(notify_chat, notify_rounds)')
      .eq('league_id', record.league_id),
  ]);

  // curated push: chat -> notify_chat, round -> notify_rounds, everything else
  // (moment / announce / system) always delivers.
  const wants = (p: { notify_chat?: boolean; notify_rounds?: boolean } | null) => {
    if (record.kind === 'chat') return p?.notify_chat ?? true;
    if (record.kind === 'round') return p?.notify_rounds ?? true;
    return true;
  };
  const recipients = (members ?? [])
    .filter((m) => m.id !== record.member_id) // never ping the author
    .filter((m) => wants(m.profiles))
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
  console.log(`[push] kind=${record.kind} recipients=${recipients.length}`);
  await sendTo(recipients, n.title, n.body);
  return reply('sent', { kind: record.kind, recipients: recipients.length });
});
