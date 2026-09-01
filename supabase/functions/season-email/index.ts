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

/* D77 copy notes (kept OUT of the template — an HTML comment inside it ships
   in every email):
   · the headline said "take the Cup" under a name that may be one golfer
     ("Jerecho take the Cup"), and the subject said "takes" — so the two could
     never both be right. A label, not a verb, is correct for a squad AND a
     solo champion, and it now matches the subject exactly.
   · the CTA hardcoded "Season 2", so a league finishing its third season was
     invited to its second, and it presumed a next season the crew may not have
     decided on. It states what the tap does now, nothing more. */
function buildHtml(p: Payload, r: Recipient) {
  const margin =
    p.champion_score != null && p.runnerup_score != null
      ? Math.round((p.champion_score - p.runnerup_score) * 10) / 10
      : null;
  /* '412–388' alone is two numbers; say what they are, and say who the margin
     is over — the runner-up is right there in the payload and was unused (D77) */
  const scoreLine =
    p.champion_score != null && p.runnerup_score != null
      ? `<div style="font:600 22px ui-monospace,Menlo,monospace;color:#ECEEF2;letter-spacing:.02em">
           ${esc(num(p.champion_score))}&ndash;${esc(num(p.runnerup_score))} points
         </div>
         <div style="font:12px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:5px">
           ${margin && margin > 0
             ? `${esc(num(margin))} clear${p.runner_up ? ` of ${esc(p.runner_up)}` : ''}`
             /* when a tiebreak line follows it says 'Level on points' itself —
                two lines both opening 'Level' read as a stutter */
             : (p.tiebreak ? '' : 'Level &mdash; the ladder decided it')}
         </div>`
      : '';
  /* 'DECIDED ON FEWEST ROUNDS USED' is month_rank counting-cap machinery
     printed verbatim, in all-caps monospace, so it read like a log line */
  const tie = p.tiebreak
    ? `<div style="font:12px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:8px">Level on points &mdash; ${esc(p.tiebreak)} decided it.</div>`
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
  /* "You're owed $180" with no source is the one thing a settlement line must
     not leave open — owed BY WHOM. Name the pot and who sends it. */
  const yours =
    r.cents > 0
      ? `<div style="margin:18px 0 0;padding:12px 14px;border-radius:12px;background:rgba(47,164,106,.20);border:1px solid #2FA46A">
           <div style="font:600 15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">Your cut of the pot: ${esc(money(r.cents))}</div>
           <div style="font:12px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:3px">Whoever collected it sends it on.</div>
         </div>`
      : '';
  const unsub = r.token
    ? `<a href="${APP}/?unsub=${encodeURIComponent(r.token)}" style="color:#5E665E;text-decoration:underline">Turn off season emails</a>`
    : '';

  return `<!doctype html><html><body style="margin:0;padding:0;background:#0A0E0C">
  <div style="max-width:520px;margin:0 auto;padding:28px 22px;font-family:-apple-system,Segoe UI,sans-serif">
    <div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A">Season complete</div>
    <div style="font:400 38px Georgia,serif;line-height:1.05;color:#D8B25A;margin:10px 0 4px">${esc(p.champion)}</div>
    <div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86;margin-bottom:12px">Champion &middot; ${esc(p.league)}</div>
    ${scoreLine}${tie}
    <div style="margin-top:18px;padding:12px 14px;border-radius:12px;background:#121710;border:1px solid #252C24">
      ${p.runner_up ? `<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="font:10px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:#98A29A">Runner-up</span><span style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">${esc(p.runner_up)}</span></div>` : ''}
      ${p.points_king ? `<div style="display:flex;justify-content:space-between;padding:6px 0"><span style="font:10px ui-monospace,Menlo,monospace;letter-spacing:.12em;text-transform:uppercase;color:#98A29A">Points king</span><span style="font:14px -apple-system,Segoe UI,sans-serif;color:#D8B25A">${esc(p.points_king)}</span></div>` : ''}
    </div>
    ${yours}
    ${table ? `<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A;margin:20px 0 6px">Final table</div>
    <table style="width:100%;border-collapse:collapse">${table}</table>` : ''}
    <a href="${APP}/" style="display:block;margin-top:22px;padding:13px 18px;border-radius:11px;background:#2FA46A;color:#08120C;font:600 15px -apple-system,Segoe UI,sans-serif;text-align:center;text-decoration:none">See the rounds behind it</a>
    <div style="font:11px -apple-system,Segoe UI,sans-serif;color:#5E665E;margin-top:20px;line-height:1.5">
      Cup Season keeps the ledger; the money moves between friends.<br>${unsub}
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

// D71: a league-cancellation email. Self-contained — the league is already
// gone, so everything the mail needs is in the notice's snapshot.
/* D77: "Your posted rounds stay on your card" is the reassurance that matters
   most to someone whose league just died, and it was the LAST clause of the
   smallest, dimmest text in the mail. It gets its own line now, at a size a
   worried person can actually read. */
function buildCancelHtml(league: string, r: { name: string | null; cents: number }) {
  /* 'Your buy-in · settle up between yourselves' is the middot-glued run-on
     D77 rejected — two unrelated clauses welded by a separator, in all-caps.
     A refund notice has to read as a refund in the first three words. */
  const owed = r.cents > 0
    ? `<div style="margin:14px 0 0;padding:12px 14px;border-radius:12px;background:rgba(47,164,106,.20);border:1px solid #2FA46A">
         <div style="font:600 15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">Your ${esc(money(r.cents))} buy-in comes back</div>
         <div style="font:12px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:3px">Whoever collected it sends it back.</div>
       </div>`
    : '';
  return `<!doctype html><html><body style="margin:0;padding:0;background:#0A0E0C">
  <div style="max-width:520px;margin:0 auto;padding:28px 22px;font-family:-apple-system,Segoe UI,sans-serif">
    <div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A">League cancelled</div>
    <div style="font:400 30px Georgia,serif;line-height:1.1;color:#ECEEF2;margin:10px 0 6px">${esc(league)} has been called off</div>
    <div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86">The season won't be played. Nobody won, and every buy-in comes back.</div>
    ${owed}
    <div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86;margin-top:16px">Your rounds stay on your card &mdash; all of them.</div>
    <div style="font:11px -apple-system,Segoe UI,sans-serif;color:#5E665E;margin-top:20px;line-height:1.5">
      Cup Season keeps the ledger; the money moves between friends.
    </div>
  </div></body></html>`;
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
    { id?: string; season_id?: string; sent_at?: string | null;
      payload?: { league?: string; recipients?: { email?: string; name?: string | null; cents?: number }[] } };

  // D71: a cancellation_notices row carries a self-contained payload (the league
  // is already deleted). Handle it before the season-recap path — it has no
  // season_id.
  if (rec.payload && Array.isArray(rec.payload.recipients)) {
    if (rec.sent_at) return new Response('already sent', { status: 200 });
    const league = String(rec.payload.league ?? 'your league');
    let cs = 0, cf = 0;
    for (const r of rec.payload.recipients) {
      if (!r?.email) continue;
      /* 'your buy-in' is a bare noun with no verb: from the subject alone the
         recipient cannot tell whether their money is coming back or gone, so a
         refund notice read as a loss notice. The cents are per-recipient and
         already in hand here — say the number. */
      const cents = r.cents ?? 0;
      const subj = cents > 0
        ? `${league} is off — your ${money(cents)} comes back`
        : `${league} is off`;
      const ok = await sendEmail(r.email, r.name ?? null,
        subj, buildCancelHtml(league, { name: r.name ?? null, cents }));
      ok ? cs++ : cf++;
    }
    console.log(`[season-email] cancellation notice=${rec.id} sent=${cs} failed=${cf}`);
    if (rec.id) await sb.rpc('mark_cancellation_sent', { p_id: rec.id, p_error: cf ? `${cf} failed` : null });
    return new Response(JSON.stringify({ cancelled: true, sent: cs, failed: cf }), {
      status: 200, headers: { 'content-type': 'application/json' } });
  }

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
  /* 'takes' is singular under a name that is usually a SQUAD ("Mudsharks takes
     the Cup"), and the headline inside said 'take' — so subject and headline
     could never both be right. 'The Cup goes to' is correct either way, and
     carrying the margin makes the subject answer the question by itself. */
  const gap = p.champion_score != null && p.runnerup_score != null
    ? Math.round((p.champion_score - p.runnerup_score) * 10) / 10
    : null;
  /* `solo` (added 20260727240000) is the only thing that can tell a squad name
     from a person's, and without it this had to print a full legal name to
     avoid shortening "Mudsharks" to "Mudshark". First names go in the SUBJECT,
     where inbox previews truncate hardest; the headline inside keeps the full
     name, because that one is an honour line and wants the whole of it. */
  const champ = p.solo ? String(p.champion ?? '').trim().split(/\s+/)[0] || p.champion : p.champion;
  const subject = `The Cup goes to ${champ}${gap && gap > 0 ? ` by ${num(gap)}` : ''} — ${p.league}`;

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
