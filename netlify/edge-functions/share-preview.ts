/* ============================================================================
 * share-preview — per-token Open Graph tags for /?share=TOKEN
 *
 * THE PROBLEM. Cup Season is a single-file client-rendered PWA, so every share
 * link served the same seven static <meta> tags from index.html's <head>. A
 * settled match, a career round and a whole season all previewed identically:
 * "Cup Season — season-long fantasy golf for your crew" over the brand image.
 * The pilot texted a 3&2 win to his group and the preview card said nothing
 * about it. Link previews are the entire first impression for everyone who is
 * not yet a user, and ours was blank.
 *
 * A scraper (iMessage, WhatsApp, Slack, Twitter, Discord) does not run
 * JavaScript. document.title set at render time reaches nobody. The tags have
 * to be correct in the bytes we serve, which means rewriting them at the edge.
 *
 * WHAT IT DOES. On a request to / carrying ?share=<uuid>, fetch the same anon
 * share_info RPC the public page itself calls, then rewrite the head tags in
 * the passed-through HTML. Everything else — every ordinary app load — returns
 * before any work happens.
 *
 * FAIL-OPEN, EVERYWHERE. Bad token, RPC down, revoked share, unexpected shape,
 * any thrown error: serve the original bytes. A broken preview is a bad day; a
 * broken app is an outage. There is no path here that can return less than
 * what the origin already returns.
 *
 * CREDENTIALS. Read from Netlify env when set, otherwise parsed out of the
 * HTML we are already holding. Nothing new is exposed: the project URL and the
 * publishable key ship inside index.html to every visitor by construction, and
 * share_info is one of the seven deliberate anon endpoints (D37/D57). Parsing
 * them rather than hardcoding means the function can never drift from the
 * client — if the key is rotated in index.html, this follows in the same
 * deploy. The service-role key must NEVER appear here.
 *
 * DEPLOY. Netlify picks edge functions up from netlify/edge-functions/ in the
 * repo, NOT from the publish directory, so this is deliberately absent from
 * stamp-version.sh's dist allowlist (OPS-C7) — it is executed, never served.
 * ========================================================================== */

import type { Config, Context } from 'https://edge.netlify.com';

const STATIC_IMG = 'https://cupseason.app/og-image.png?v=3';
const STATIC_W = '1200', STATIC_H = '630';

/* the token is interpolated into a URL and an HTTP body — anything that is not
   a plain UUID is refused before it reaches either */
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const esc = (s: unknown) =>
  String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

/* Collapse to one line and cap. A description is rendered as a single clamped
   line by every scraper; a stray newline can terminate the attribute early. */
const oneLine = (s: unknown, max = 200) => {
  const t = String(s ?? '').replace(/\s+/g, ' ').trim();
  return t.length > max ? t.slice(0, max - 1).trimEnd() + '…' : t;
};

/* a plus-handicap reads "+2.1"; a normal index reads "12.4" — never a minus */
const fmtIdx = (v: unknown) => {
  const n = Number(v);
  if (!isFinite(n)) return '';
  return n < 0 ? '+' + Math.abs(n).toFixed(1) : n.toFixed(1);
};

const DW = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MO = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
/* played_on is a bare 'YYYY-MM-DD'. new Date() on that parses as UTC midnight
   and renders the PREVIOUS day west of Greenwich — the same landmine the client
   carries a localDate() helper for. Split the string instead. */
const fmtDate = (iso: unknown) => {
  const m = String(iso ?? '').match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) return '';
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  return `${DW[d.getDay()]} · ${MO[d.getMonth()]} ${d.getDate()}`;
};

/* Replace a tag's content in place; append before </head> if it is absent, so
   a future head edit that drops a tag cannot silently disable a preview. */
function setTag(html: string, sel: 'property' | 'name', key: string, value: string) {
  const re = new RegExp(`(<meta\\s+${sel}=["']${key}["']\\s+content=["'])[^"']*(["']\\s*/?>)`, 'i');
  if (re.test(html)) return html.replace(re, `$1${value}$2`);
  return html.replace(/<\/head>/i, `<meta ${sel}="${key}" content="${value}"></head>`);
}

function setTitle(html: string, value: string) {
  return /<title>[\s\S]*?<\/title>/i.test(html)
    ? html.replace(/<title>[\s\S]*?<\/title>/i, `<title>${value}</title>`)
    : html.replace(/<\/head>/i, `<title>${value}</title></head>`);
}

type Meta = { title: string; desc: string; img: string; w: string; h: string };

function metaFor(info: any, storage: string, token: string): Meta | null {
  if (!info || !info.kind) return null;
  const when = fmtDate(info.played_on);

  if (info.kind === 'round') {
    const name = info.name || 'A golfer';
    const gross = info.gross != null ? String(info.gross) : '';
    return {
      title: gross ? `${name} shot ${gross} at ${info.course || 'the course'}` : `${name} posted a round`,
      /* "Cup Season" closes the line, so the qualifier goes before it — trailing
         it read as "Cup Season (nine holes)" */
      desc: [when, info.holes === 9 ? 'Nine holes' : '',
             info.points != null ? `${info.points} points` : '', 'Cup Season']
        .filter(Boolean).join(' · '),
      /* the photo already travels to the public bucket at share time (D60) —
         when there is one it IS the preview */
      img: info.photo ? `${storage}/${token}.jpg` : STATIC_IMG,
      w: info.photo ? '1600' : STATIC_W,
      h: info.photo ? '1600' : STATIC_H,
    };
  }

  if (info.kind === 'settlement') {
    const r = info.result || {};
    /* D77 put the result first in `share`; prefer it over the feed row */
    const headline = r.share || r.story
      || (r.winner != null
        ? `${r.winner === '0' ? r.side_a : r.side_b} beat ${r.winner === '0' ? r.side_b : r.side_a} ${r.status || ''}`
        : 'A match was settled');
    return {
      title: oneLine(headline, 90),
      desc: [info.course, when, 'Cup Season'].filter(Boolean).join(' · '),
      img: `${storage}/${token}.png`,   /* the settlement card, if it travelled */
      w: '1080', h: '1350',
    };
  }

  if (info.kind === 'card') {
    /* D186 — the golfer as the preview. The number IS the headline: without it
       the card reads "someone is on Cup Season", which is the generic card
       this function exists to eliminate. share_info decides whether the number
       travels (discoverable), so a withheld one falls back to the rounds line
       rather than guessing. */
    const name = info.name || 'A golfer';
    const idx = info.index_current;
    const rounds = info.career?.rounds;
    return {
      title: idx != null ? `${name} plays to ${fmtIdx(idx)}` : `${name} is on Cup Season`,
      desc: [info.city, rounds != null ? `${rounds} rounds` : '', 'Cup Season']
        .filter(Boolean).join(' · '),
      /* the face travelled at mint time (D186, same contract as D60's photo) —
         when there is one it IS the preview */
      img: info.photo ? `${storage}/${token}.jpg` : STATIC_IMG,
      w: info.photo ? '1200' : STATIC_W,
      h: info.photo ? '1200' : STATIC_H,
    };
  }

  if (info.kind === 'recap') {
    const champ = info.champion ? `${info.champion} take the Cup` : 'The season is on the books';
    return {
      title: `${info.league || 'A league'} — ${champ}`,
      desc: [info.points_king ? `Points king: ${info.points_king}` : '',
             info.status === 'complete' ? 'Final' : 'Still being played', 'Cup Season']
        .filter(Boolean).join(' · '),
      img: STATIC_IMG, w: STATIC_W, h: STATIC_H,
    };
  }
  return null;
}

export default async (request: Request, context: Context) => {
  const url = new URL(request.url);
  const token = url.searchParams.get('share');
  /* every ordinary app load leaves here, before any fetch or body read */
  if (!token || !UUID.test(token)) return;

  const res = await context.next();
  /* `html` is hoisted so the catch can still answer with the origin bytes: by
     the time anything can throw, res.body is already consumed and calling
     context.next() a second time is not a fallback, it is a second request. */
  let html: string | null = null;
  /* rebuild rather than `new Response(html, res)` — reusing the origin init
     keeps its content-length, which no longer matches the rewritten body */
  const pass = () => html == null
    ? res
    : new Response(html, { status: res.status, statusText: res.statusText, headers: stripLen(res.headers) });
  try {
    const ctype = res.headers.get('content-type') || '';
    if (!ctype.includes('text/html')) return res;

    html = await res.text();

    const env = typeof Netlify !== 'undefined' ? Netlify.env : null;
    const envUrl = env?.get('SUPABASE_URL');
    const envKey = env?.get('SUPABASE_ANON_KEY');
    const base = (envUrl || html.match(/const SUPABASE_URL\s*=\s*'([^']+)'/)?.[1] || '').replace(/\/+$/, '');
    const key = envKey || html.match(/const SUPABASE_KEY\s*=\s*'([^']+)'/)?.[1] || '';
    if (!base || !key) return pass();

    const rpc = await fetch(`${base}/rest/v1/rpc/share_info`, {
      method: 'POST',
      headers: { apikey: key, authorization: `Bearer ${key}`, 'content-type': 'application/json' },
      body: JSON.stringify({ p_token: token }),
    });
    if (!rpc.ok) return pass();

    const storage = `${base}/storage/v1/object/public/shared`;
    const meta = metaFor(await rpc.json(), storage, token);
    /* a revoked or dead token answers null (D57) — it gets the brand preview,
       never a "nothing here" card broadcast into somebody's thread */
    if (!meta) return pass();

    /* the settlement card is best-effort at share time, so confirm the object
       exists before pointing a scraper at it — a 404 og:image renders as a
       BROKEN preview, which is worse than the generic one */
    if (meta.img.endsWith('.png') && meta.img.startsWith(storage)) {
      let ok = false;
      try { ok = (await fetch(meta.img, { method: 'HEAD' })).ok; } catch { ok = false; }
      if (!ok) { meta.img = STATIC_IMG; meta.w = STATIC_W; meta.h = STATIC_H; }
    }

    const title = esc(oneLine(meta.title, 110));
    const desc = esc(oneLine(meta.desc, 200));
    const img = esc(meta.img);
    const canonical = esc(`https://cupseason.app/?share=${token}`);

    let out = html;
    out = setTitle(out, `${title} · Cup Season`);
    out = setTag(out, 'name', 'description', desc);
    out = setTag(out, 'property', 'og:title', title);
    out = setTag(out, 'property', 'og:description', desc);
    out = setTag(out, 'property', 'og:url', canonical);
    out = setTag(out, 'property', 'og:type', 'article');
    out = setTag(out, 'property', 'og:image', img);
    out = setTag(out, 'property', 'og:image:width', esc(meta.w));
    out = setTag(out, 'property', 'og:image:height', esc(meta.h));
    out = setTag(out, 'name', 'twitter:title', title);
    out = setTag(out, 'name', 'twitter:description', desc);
    out = setTag(out, 'name', 'twitter:image', img);

    const headers = stripLen(res.headers);
    /* short and revalidating: a revoked share must stop previewing quickly,
       and scrapers re-fetch far more often than people do */
    headers.set('cache-control', 'public, max-age=60, must-revalidate');
    return new Response(out, { status: res.status, statusText: res.statusText, headers });
  } catch (_e) {
    return pass();
  }
};

function stripLen(h: Headers) {
  const out = new Headers(h);
  out.delete('content-length');   /* the body's length changed under it */
  return out;
}

export const config: Config = { path: '/' };
