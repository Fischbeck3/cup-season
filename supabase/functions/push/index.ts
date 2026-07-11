// Cup Season — push sender.
// Invoked by a Database Webhook on public.posts INSERT. The board is the
// app's nervous system, so this one function covers chat, round fan-outs,
// reveals, and month closes. Auth: shared secret header (the webhook is
// configured to send x-push-secret; deploy with --no-verify-jwt).
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

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }

  const { record } = await req.json().catch(() => ({ record: null }));
  if (!record?.league_id) return new Response('ok');

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
  if (!recipients.length) return new Response('ok');

  const { data: subs } = await sb
    .from('push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('profile_id', recipients);
  if (!subs?.length) return new Response('ok');

  const payload = JSON.stringify({
    title: lg?.name ?? 'Cup Season',
    body: String(record.body ?? 'Something happened on the board').slice(0, 140),
    url: '/',
  });

  const dead: string[] = [];
  await Promise.all(subs.map(async (s) => {
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        payload,
      );
    } catch (e) {
      const code = (e as { statusCode?: number })?.statusCode;
      if (code === 404 || code === 410) dead.push(s.id); // subscription expired
    }
  }));
  if (dead.length) await sb.from('push_subscriptions').delete().in('id', dead);

  return new Response('ok');
});
