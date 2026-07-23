// Cup Season — season-end email (D68). rev 2026-07-25
// Invoked by a Database Webhook:
//   - public.email_queue INSERT  -> one send per season close
// Auth: shared secret header (x-push-secret), same as the push function.
// Deploy with --no-verify-jwt.
//
// Secrets required (supabase secrets set):
//   PUSH_WEBHOOK_SECRET  — shared with the push webhook
//   BREVO_API_KEY        — Brevo transactional API key (already used by push
//                          for friend-request mail)
// Optional:
//   BREVO_SENDER         — authorised sender address; defaults below
//   APP_URL              — defaults to https://cupseason.app
//
// This function holds NO game logic. season_email_payload() composes every
// fact — champion, margin, standings, each recipient's own payout and their
// unsubscribe token — and filters bot/placeholder addresses, so a sandbox
// league physically cannot mail anyone.

import { createClient } from 'npm:@supabase/supabase-js@2';

const sb = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const APP = Deno.env.get('APP_URL') ?? 'https://cupseason.app';

type Recipient = { email: string; name: string | null; token: string | null; cents: number };
type Payload = {
  season_id: string; league: string; champion: string;
  runner_up: string | null; points_king: string | null;
  champion_score: number | null; runnerup_score: number | null;
  tiebreak: string | null; starts_on: string; ends_on: string;
  rows: { name: string; points: number }[];
  recipients: Recipient[];
};

const esc = (s: unknown) =>
  String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));

const money = (cents: number) => {
  const v = (cents || 0) / 100;
  return '$' + (Math.round(v * 100) % 100 === 0 ? String(Math.round(v)) : v.toFixed(2));
};

const num = (v: number | null) =>
  v == null ? '' : (Number(v) === Math.floor(Number(v)) ? String(Math.round(Number(v))) : Number(v).toFixed(1));

function buildHtml(p: Payload, r: Recipient) {
  const margin =
    p.champion_score != null && p.runnerup_score != null
      ? Math.round((p.champion_score - p.runnerup_score) * 10) / 10
      : null;
  const scoreLine =
    p.champion_score != null && p.runnerup_score != null
      ? `<div style="font:600 22px ui-monospace,Menlo,monospace;color:#ECEEF2;letter-spacing:.02em">
           ${esc(num(p.champion_score))}&ndash;${esc(num(p.runnerup_score))}
         </div>
         <div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.14em;text-transform:uppercase;color:#98A29A;margin-top:4px">
           ${margin && margin > 0 ? `by ${esc(num(margin))}` : 'level &mdash; the ladder decided it'}
         </div>`
      : '';
  const tie = p.tiebreak
    ? `<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:#98A29A;margin-top:8px">decided on ${esc(p.tiebreak)}</div>`
    : '';
  const table = (p.rows || [])
    .map(
      (row, i) => `<tr>
        <td style="padding:7px 0;border-bottom:1px solid #252C24;font:12px ui-monospace,Menlo,monospace;color:#5E665E;width:28px">${String(i + 1).padStart(2, '0')}</td>
        <td style="padding:7px 0;border-bottom:1px solid #252C24;font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">${esc(row.name)}</td>
        <td style="padding:7px 0;border-bottom:1px solid #252C24;font:600 14px ui-monospace,Menlo,monospace;color:#ECEEF2;text-align:right">${esc(row.points)}</td>
      </tr>`,
    )
    .join('');
  const yours =
    r.cents > 0
      ? `<div style="margin:18px 0 0;padding:12px 14px;border-radius:12px;background:rgba(47,164,106,.20);border:1px solid #2FA46A">
           <div style="font:600 15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">You&rsquo;re owed ${esc(money(r.cents))}</div>
           <div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.1em;text-transform:uppercase;color:#98A29A;margin-top:3px">Settle between yourselves</div>
         </div>`
      : '';
  const unsub = r.token
    ? `<a href="${APP}/?unsub=${encodeURIComponent(r.token)}" style="color:#5E665E;text-decoration:underline">Turn off season emails</a>`
    : '';

  return `<!doctype html><html><body style="margin:0;padding:0;background:#0A0E0C">
  <div style="max-width:520px;margin:0 auto;padding:28px 22px;font-family:-apple-system,Segoe UI,sans-serif">
    <div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A">Season complete</div>
    <div style="font:400 38px Georgia,serif;line-height:1.05;color:#D8B25A;margin:10px 0 4px">${esc(p.champion)}</div>
    <div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86;margin-bottom:12px">take the Cup &mdash; ${esc(p.league)}</div>
    ${scoreLine}${tie}
    <div style="margin-top:18px;padding:12px 14px;border-radius:12px;background:#121710;border:1px solid #252C24">
      ${p.runner_up ? `<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="font:10px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:#98A29A">Runner-up</span><span style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">${esc(p.runner_up)}</span></div>` : ''}
      ${p.points_king ? `<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="font:10px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:#98A29A">Points king</span><span style="font:14px -apple-system,Segoe UI,sans-serif;color:#D8B25A">${esc(p.points_king)}</span></div>` : ''}
    </div>
    ${yours}
    ${table ? `<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A;margin:20px 0 6px">Final table</div>
    <table style="width:100%;border-collapse:collapse">${table}</table>` : ''}
    <a href="${APP}/" style="display:block;margin-top:22px;padding:13px 18px;border-radius:11px;background:#2FA46A;color:#08120C;font:600 15px -apple-system,Segoe UI,sans-serif;text-align:center;text-decoration:none">Run it back &mdash; Season 2</a>
    <div style="font:11px -apple-system,Segoe UI,sans-serif;color:#5E665E;margin-top:20px;line-height:1.5">
      Cup Season keeps the books &mdash; money moves friend-to-friend, never through us.<br>${unsub}
    </div>
  </div></body></html>`;
}

async function sendEmail(to: string, name: string | null, subject: string, html: string) {
  const key = Deno.env.get('BREVO_API_KEY');
  if (!key) { console.log('[season-email] BREVO_API_KEY unset — skipping'); return false; }
  try {
    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: { 'api-key': key, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify({
        sender: { name: 'Cup Season', email: Deno.env.get('BREVO_SENDER') ?? 'hello@cupseason.app' },
        to: [{ email: to, name: name || undefined }],
        subject,
        htmlContent: html,
      }),
    });
    if (res.status >= 300) {
      console.log(`[season-email] status=${res.status} body=${(await res.text().catch(() => '')).slice(0, 200)}`);
      return false;
    }
    return true;
  } catch (e) {
    console.error(`[season-email] send failed msg=${(e as Error)?.message ?? e}`);
    return false;
  }
}

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }
  // Be liberal in what we accept: a Database Webhook sends {record}, but the
  // same hook can be wired as a plain HTTP request, and a manual curl sends the
  // row bare. Never bail SILENTLY — the first live run returned 200 "ok" with
  // no log line at all, which looked identical to "webhook not wired".
  let body: Record<string, unknown> | null = null;
  try { body = await req.json(); } catch { console.log('[season-email] body parse failed / empty'); }
  const rec = (body?.record ?? body?.new ?? body ?? {}) as
    { id?: string; season_id?: string; sent_at?: string | null };
  if (!rec.id || !rec.season_id) {
    console.log('[season-email] no usable record'
      + ` topKeys=[${Object.keys(body ?? {}).join(',')}]`
      + ` recordKeys=[${Object.keys((body?.record ?? {}) as object).join(',')}]`);
    return new Response('no record', { status: 200 });
  }
  const row = rec;
  if (row.sent_at) return new Response('already sent', { status: 200 });
  console.log(`[season-email] invoked queue=${row.id} season=${row.season_id}`);

  const { data, error } = await sb.rpc('season_email_payload', { p_season: row.season_id });
  if (error || !data) {
    await sb.rpc('mark_email_sent', { p_id: row.id, p_error: error?.message ?? 'no payload' });
    return new Response('no payload', { status: 200 });
  }
  const p = data as Payload;
  const subject = `${p.champion} takes the Cup — ${p.league}`;

  let sent = 0, failed = 0;
  for (const r of p.recipients || []) {
    const ok = await sendEmail(r.email, r.name, subject, buildHtml(p, r));
    ok ? sent++ : failed++;
  }
  console.log(`[season-email] season=${row.season_id} sent=${sent} failed=${failed}`);
  await sb.rpc('mark_email_sent', {
    p_id: row.id,
    p_error: failed ? `${failed} of ${sent + failed} failed` : null,
  });
  return new Response(JSON.stringify({ sent, failed }), {
    status: 200, headers: { 'content-type': 'application/json' },
  });
});
