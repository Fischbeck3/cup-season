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

async function sendTo(profileIds: string[], title: string, body: string) {
  if (!profileIds.length) return;
  const { data: subs } = await sb
    .from('push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('profile_id', profileIds);
  if (!subs?.length) { console.log('[push] no subs for recipients'); return; }

  const payload = JSON.stringify({ title, body: body.slice(0, 140), url: '/' });
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

function friendRequestEmail(toName: string, fromName: string, fromHandle: string) {
  const greeting = toName ? `Hi ${toName},` : 'Hi,';
  const who = fromHandle ? `${fromName} (@${fromHandle})` : fromName;
  return `<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;color:#1a2620">
    <p style="font-size:16px;line-height:1.5">${greeting}</p>
    <p style="font-size:16px;line-height:1.5"><strong>${who}</strong> added you as a golf buddy on Cup Season.</p>
    <p style="font-size:16px;line-height:1.5">Open the app to accept and you'll see each other's rounds and scores.</p>
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
  if (!record) return new Response('ok');

  if (table === 'friendships') {
    const who = async (id: string) => {
      const { data } = await sb.from('profiles')
        .select('display_name, handle, email').eq('id', id).maybeSingle();
      return data;
    };
    if (type === 'INSERT' && record.status === 'pending') {
      const [p, a] = await Promise.all([who(record.requester), who(record.addressee)]);
      console.log('[push] kind=friend-request');
      await sendTo([record.addressee], 'Cup Season',
        `${p?.display_name ?? 'A golfer'} (@${p?.handle ?? '?'}) wants to be golf buddies`);
      // Requests only (pilot decision) — email the person who was added.
      await sendEmail(
        a?.email ?? '', a?.display_name ?? '',
        `${p?.display_name ?? 'A golfer'} added you on Cup Season`,
        friendRequestEmail(a?.display_name ?? '', p?.display_name ?? 'A golfer', p?.handle ?? ''),
      );
    } else if (type === 'UPDATE' && record.status === 'accepted' && old_record?.status === 'pending') {
      const p = await who(record.addressee);
      console.log('[push] kind=friend-accept');
      await sendTo([record.requester], 'Cup Season',
        `${p?.display_name ?? 'Your buddy'} accepted — you're golf buddies`);
    }
    return new Response('ok');
  }

  // opt-in duel taunts (the Ryder, batch-3 #17): one row = one recipient
  if (table === 'push_nudges') {
    console.log('[push] kind=nudge');
    await sendTo([record.profile_id], record.title ?? 'The Ryder', String(record.body ?? ''));
    return new Response('ok');
  }

  // event board posts (the Ryder): fan to the event's players
  if (!record.league_id) {
    if (!record.event_id) return new Response('ok');
    const [{ data: evt }, { data: eps }] = await Promise.all([
      sb.from('events').select('name').eq('id', record.event_id).maybeSingle(),
      sb.from('event_players').select('profile_id').eq('event_id', record.event_id),
    ]);
    const recipients = (eps ?? []).map((e) => e.profile_id);
    console.log(`[push] kind=${record.kind} event recipients=${recipients.length}`);
    await sendTo(recipients, evt?.name ?? 'The Ryder',
      String(record.body ?? 'Something happened in your event'));
    return new Response('ok');
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
  console.log(`[push] kind=${record.kind} recipients=${recipients.length}`);
  await sendTo(recipients, lg?.name ?? 'Cup Season',
    String(record.body ?? 'Something happened on the board'));

  return new Response('ok');
});
