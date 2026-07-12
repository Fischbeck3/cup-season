// Cup Season — push sender. rev 2026-07-12b (social graph)
// Invoked by Database Webhooks:
//   - public.posts INSERT           -> league board fan-out
//   - public.friendships INSERT/UPDATE -> friend request / accept pings
// Auth: shared secret header (x-push-secret); deploy with --no-verify-jwt.
//
// Secrets required (supabase secrets set):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY, VAPID_SUBJECT, PUSH_WEBHOOK_SECRET

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

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }

  const { type, table, record, old_record } = await req.json().catch(() => ({}));
  if (!record) return new Response('ok');

  if (table === 'friendships') {
    const who = async (id: string) => {
      const { data } = await sb.from('profiles')
        .select('display_name, handle').eq('id', id).maybeSingle();
      return data;
    };
    if (type === 'INSERT' && record.status === 'pending') {
      const p = await who(record.requester);
      console.log('[push] kind=friend-request');
      await sendTo([record.addressee], 'Cup Season',
        `${p?.display_name ?? 'A golfer'} (@${p?.handle ?? '?'}) wants to be golf buddies`);
    } else if (type === 'UPDATE' && record.status === 'accepted' && old_record?.status === 'pending') {
      const p = await who(record.addressee);
      console.log('[push] kind=friend-accept');
      await sendTo([record.requester], 'Cup Season',
        `${p?.display_name ?? 'Your buddy'} accepted — you're golf buddies`);
    }
    return new Response('ok');
  }

  // default branch: league board posts
  if (!record.league_id) return new Response('ok');

  const [{ data: lg }, { data: members }] = await Promise.all([
    sb.from('leagues').select('name').eq('id', record.league_id).maybeSingle(),
    sb.from('league_members')
      .select('id, profile_id, profiles(notify_chat)')
      .eq('league_id', record.league_id),
  ]);

  const recipients = (members ?? [])
    .filter((m) => m.id !== record.member_id) // never ping the author
    .filter((m) => record.kind !== 'chat' || (m.profiles?.notify_chat ?? true))
    .map((m) => m.profile_id);
  console.log(`[push] kind=${record.kind} recipients=${recipients.length}`);
  await sendTo(recipients, lg?.name ?? 'Cup Season',
    String(record.body ?? 'Something happened on the board'));

  return new Response('ok');
});
