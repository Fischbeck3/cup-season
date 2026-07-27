# Cup Season — outbound copy audit

Every string that leaves the app: share sheet, clipboard, board posts, push, email, landing pages, OG metadata. Generated 2026-07-27 against commit b679bea (= live prod).

Severity: **broken** = wrong or unreadable · **confusing** = right but the reader has to work · **wordy** = right, too long · **fine** = keep.

Totals: 128 rewrites across 5 surfaces, plus 49 items outside those surfaces and 95 rename occurrences.

---

## share-sheet

Every outbound body on this surface is a board row, a scoreboard dump, or a naked URL — three things nobody writes in a text thread. The single structural fix is to stop reusing `result.story` (built for the feed, upcased and capped by the server) as share text and give each game builder a purpose-built `share` key: result first, first names only, ASCII only, under 60 chars, money only when it is already computed in scope. Do that plus a hoisted `fn1` first-name reducer and the four bottleneck builders, and eighteen of these twenty items fall out; the two that remain are the naked-UUID growth links (7973, 6041), which need words attached, and the static og tags, which need a prerender that copy cannot supply.

### `index.html`:7986 — broken  (115 → 36 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2
```

**Source**

```js
/* the share body is NOT the board row — `story` is composed for the feed (the
   server upcases and caps it); `share` is composed for someone's thread. The
   settlement page carries the sides, the card, the hole-by-hole and the money;
   this line only has to make a person tap it. */
document.getElementById('lrShareLink')?.addEventListener('click',()=>csShareLink('settlement', lrId,
    (result?.share || 'The match is settled').slice(0,70)));
```

**Why** THE REPORTED FAILURE. Reading `result.story` is the root cause: one string was doing a feed job and a text-message job and was tuned for neither. Switching the read to a new `share` key (added at each builder below) is the whole fix — the 120-char cap disappears because nothing being read is long any more. The 70 remains only as a policy backstop, and the `|| 'The match is settled'` fallback replaces `${result?.side_a || 'The match'} vs ${result?.side_b || ''}`, which shipped no result at all. Names come from `fn1()` inside the builders, never here.

### `index.html`:7186 — broken  (115 → 36 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2
```

**Source**

```js
/* first names for anything that leaves the app (share-copy rule 3) — hoist
   next to theirs() at 5132 so every builder reaches the same one:
     const fn1 = n => String(n||'').trim().split(/\s+/)[0] || 'Someone';  */
  const fnSide = t => MTEAMS[t].map(i=>fn1(LIVE[i]?.n)).filter(Boolean).join(' & ');
  const bankTxt = m.bank===0 ? 'bank empty'
    : `bank: ${names(m.bank>0?0:1)}${unit>0?` $${Math.abs(m.bank)*unit}`:` ${Math.abs(m.bank)} unit${Math.abs(m.bank)===1?'':'s'}`}`;
  const money = (unit>0 && m.bank!==0) ? ` for $${Math.abs(m.bank)*unit}` : '';
  /* board row — full names, the bank by its real name, the mode by its real
     name ("Sunningdale Rules"; bare "Sunningdale" read as the venue) */
  const story = winner==null
    ? `Sunningdale Rules: ${names(0)} and ${names(1)} halved it · ${bankTxt}`
    : `Sunningdale Rules: ${names(winner)} def. ${names(winner===0?1:0)} ${status} · ${bankTxt}`;
  /* the text message — result first, first names, ASCII, no mode label */
  const share = winner==null
    ? `${fnSide(0)} and ${fnSide(1)} halved it`
    : `${fnSide(winner)} beat ${fnSide(winner===0?1:0)} ${status}${money}`;
  /* … and add `share` to the return at 7189 */
```

**Why** Splits the dual-use string. `share` leads with who won and by how much (36 chars, one clause, ASCII throughout — no U+00B7, so nothing for the receiving app to re-encode). `names()` at 7176 joins raw profiles.display_name ('Jerecho Fischbeck'), so `fnSide()` reduces each to the first whitespace token before joining. Dropped from the message: the 13-char mode label, 'no handicaps' (a config echo — and 'Sunningdale Rules' already means scratch), and the entire bank clause, which repeated the winners' names a second time and spent 32 of 115 chars saying nothing a reader could act on. When there is real money the bank collapses to `for $30`, the only part of it a person cares about. The board `story` keeps the bank and full names — a feed row has the app's context around it — but takes the ruled mode name and loses 'no handicaps' there too.

### `index.html`:7843 — broken  (40 → 44 chars)

**Now**

```
Jerecho Fischbeck & Jade vs Will & Isaak
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2 for $20
```

**Source**

```js
  const fnSide = t => MTEAMS[t].map(i=>fn1(LIVE[i]?.n)).filter(Boolean).join(' & ');
  const stake = state.live.stake||0;
  const share = winner==null
    ? `${fnSide(0)} and ${fnSide(1)} halved it`
    : `${fnSide(winner)} beat ${fnSide(winner===0?1:0)} ${String(status).toLowerCase()}${stake>0?` for $${stake}`:''}`;
  return { game:'match', winner: winner==null?null:String(winner), status,
           a:m.a, b:m.b, thru:m.played, stake,
           side_a:names(0), side_b:names(1), share };
```

**Why** THE WORST BUG ON THE SURFACE: plain Match Play — the flagship tee-sheet game — shared a settlement with no winner and no score, while `winner` and `status` sat unused two lines above. This is the one item where the rewrite is longer than the original, because the original was missing the news. Adds only `share`, not `story`: `finish_live_round` composes the match board row itself from the two sides and only PREFERS `p_result->>'story'` when present (migration 20260726120000_match_story_override.sql), so introducing a `story` key here would silently reroute the board — `share` is inert to the server. `status` is uppercased at 7841 ('2 UP THRU 17') for the card, so the share lowercases it; a shouted clause in a text thread reads as a different voice. `fnSide` again for first names.

### `index.html`:7238 — broken  (131 → 29 chars)

**Now**

```
Sunningdale, everyone for themselves: Jerecho Fischbeck 6, Jade 4, Will 3, Isaak 1 · no handicaps · bank: Jerecho Fischbec
```

**Proposed**

```
Jerecho won the most holes, 6
```

**Source**

```js
  const top=order[0], bo=m.bank.owner;
  const share = (unit>0 && m.bank.units>0)
    ? `${fn1(LIVE[bo]?.n)} takes $${m.bank.units*unit} from each of us`
    : `${fn1(LIVE[top]?.n)} won the most holes, ${m.wins[top]}`;
  return { game:'sunningdale', mode:'solo', unit, thru:m.played,
    players:LIVE.map((p,i)=>({name:p.n, wins:m.wins[i]})),
    bank:m.bank,
    story:`Sunningdale Rules, everyone for themselves: ${line} · ${bankTxt}`, share };
```

**Why** At 131 chars this one actually TRUNCATED at 7987's .slice(0,120) and cut the bank owner's name mid-word — the single most important name in the sentence (the 'before' above is the truncated form as it reached the share sheet). The share is 29 chars and cannot truncate. Two branches because two different facts are true: with money on it the news is the liability, phrased the way a person says it ('Jerecho takes $18 from each of us', 32 chars) rather than 'bank: … 6 units'; with no money the news is who won the most holes. They are kept separate on purpose — in Sunningdale Rules the bank belongs to whoever last won a hole, which is not necessarily the player who won the most, so collapsing them into one 'Jerecho won it' would sometimes be a lie. Board row takes the ruled mode name 'Sunningdale Rules' and loses 'no handicaps'.

### `index.html`:10654 — broken  (81 → 28 chars)

**Now**

```
Jerecho Fischbeck takes The Copper Jug — 90, 2 under their number · cupseason.app
```

**Proposed**

```
Jerecho takes The Copper Jug
```

**Source**

```js
const text=`${fn1(d.name)} takes ${d.jug}`;
```

**Why** ACTIVELY MISLEADING, which is why this is broken and not merely wordy: `mjVs()` (10442) returns 'UNDER'/'OVER', so the caption rendered '2 under their number' — and in a golf thread '2 under' reads as two under PAR on a 90, not two under a handicap number. The app maintains bandName()/vsPhrase() (5114-5127) precisely to keep that ambiguity out of player-facing copy, and this string routed around them. The fix is to say none of it: the PNG already prints the name (y=412), the gross (y=760), the vs line (y=850), the jug (y=1064) and the domain (y=1292), so the caption's only job is to name the champion and the trophy for a thread about to see the image. First name via `fn1()`. Bare 'cupseason.app' goes for the same reason as 5214 — no protocol, no linkification, and no `url` field on the share at 10656 to carry a preview.

### `index.html`:10809 — broken  (6 → 60 chars)

**Now**

```
clipboard: "PIGL26"  ·  toast: "Invite code PIGL26 copied: text it to the group"
```

**Proposed**

```
clipboard: "Jerecho wants you in PIGL\nhttps://cupseason.app/?join=PIGL26"  ·  toast: "Invite copied. Paste it to the crew."
```

**Source**

```js
const code=(!state.demo && window.CS?.league?.code) || 'SNDYCUP';
  const nm  =(!state.demo && window.CS?.league?.name) || 'The Sunday Cup';
  const who = fn1(window.CS?.profile?.display_name);
  const url = 'https://cupseason.app/?join=' + encodeURIComponent(code);
  const msg = (who ? `${who} wants you in ${nm}` : `You're in ${nm} if you want it`) + '\n' + url;
  try{ await navigator.clipboard.writeText(msg); toast('Invite copied. Paste it to the crew.'); }
  catch(e){ toast('Copy this: ' + url); }
```

**Why** The only rewrite here that gets LONGER on purpose: the clipboard payload was a bare six-character code, which pasted into a thread is six characters that mean nothing and lead nowhere — and the toast then explicitly instructed the user to text exactly that. Matching shareInvite's body and URL makes the E1 fallback produce the same artifact as the primary path instead of a strictly worse one. Two correctness fixes ride along: the clipboard failure was swallowed by `catch(e){}` while the toast still claimed 'copied', so the user was told a copy happened that may not have — the toast now lives inside the try — and the catch shows the URL rather than nothing. 'the group' becomes 'the crew'. char counts are the clipboard payload.

### `index.html`:19 — broken  (161 → 55 chars)

**Now**

```
og:title "Cup Season — season-long fantasy golf for your crew" · og:description "Rally your crew and post the real rounds you already play. Captains draft squads, points build for months, the endgame settles it — and the pot stays on the books." · og:image the static og-image.png
```

**Proposed**

```
og:title "Cup Season — season-long fantasy golf for your crew" · og:description "The round, the result, and who owes who. Tap to see it." · og:image the static og-image.png
```

**Source**

```js
<meta property="og:image" content="https://cupseason.app/og-image.png?v=3">
<meta property="og:title" content="Cup Season — season-long fantasy golf for your crew">
<meta property="og:description" content="The round, the result, and who owes who. Tap to see it.">
```

**Why** COPY CAN ONLY DO HALF OF THIS ONE; char counts are og:description. The old description was 161 characters of pitch written at a stranger, shown underneath a result being sent between four people who already play together; 55 characters describing what is on the other side of the tap serve both audiences and stop the preview arguing with the message above it. og:title is left alone deliberately — it is the one line that has to explain the app to a guest opening a claim link, and it already does; changing it would be churn. The structural half is out of copy's reach and belongs in its own task: these tags live in the SPA shell (15-21), so one preview serves every artifact the app can share, and no rewrite makes the card show 'Jerecho & Jade 3&2'. That needs a Netlify edge function or prerender that reads /?share=TOKEN and emits per-token og:title/og:description/og:image. Worth stating plainly, because it is the causal chain behind the owner's whole complaint: the preview carried nothing, so the message body was made to carry everything, which is how it became a 120-char run-on. Fix the preview and short messages become safe. Separately, the card shares at 5228 and 10656 pass no `url` at all, so they get no preview whatsoever.

### `index.html`:7858 — confusing  (58 → 20 chars)

**Now**

```
Wolf: Jerecho Fischbeck +3, Jade −1, Will +1, Isaak −3 pts
```

**Proposed**

```
Jerecho won the wolf
```

**Source**

```js
  const line=LIVE.map((p,i)=> val>0
    ? `${p.n} ${pts[i]>=0?'+':'-'}$${Math.abs(pts[i]*val)}`
    : `${p.n} ${pts[i]>=0?'+':''}${pts[i]}`).join(', ');
  const rank=pts.map((v,i)=>({v,i})).sort((a,b)=>b.v-a.v);
  const tied=rank[1] && rank[1].v===rank[0].v;
  const share = (!rank.length || rank[0].v<=0 || tied)
    ? 'Wolf ended level'
    : `${fn1(LIVE[rank[0].i]?.n)} won the wolf${val>0?`, up $${rank[0].v*val}`:''}`;
  return { game:'wolf', stake:val,
    players:LIVE.map((p,i)=>({name:p.n, pts:pts[i]})),
    transfers:settleTransfers(pts, val),
    story:`Wolf: ${line}${val>0?` · $${val}/pt`:' pts'}`, share };
```

**Why** A four-name ledger is not a result — the reader had to compare signed integers to work out who won. `share` declares the winner and, when there is money, the one number that matters ('Jerecho won the wolf, up $12' = 28 chars); the per-player ledger and the $/pt rate stay on the settlement page, which is what the link is for. `fn1()` on the winner only — one name instead of four is the difference between 20 chars and 58. Also swaps the typographic minus U+2212 at 7853 for ASCII '-': the board does not need it, and it was one of the non-ASCII characters sitting next to a bare URL in the body the owner got back percent-encoded. Ties and a nobody-ahead board fall to 'Wolf ended level' rather than crowning a leader who isn't one.

### `index.html`:7868 — confusing  (60 → 20 chars)

**Now**

```
Skins: Jerecho Fischbeck 3, Jade 2, Isaak 1 · 2 carried died
```

**Proposed**

```
Jerecho took 3 skins
```

**Source**

```js
  const died = Math.max(0, sk.carry-1);
  const best = winners.slice().sort((a,b)=>b.skins-a.skins)[0];
  const tied = best && winners.filter(w=>w.skins===best.skins).length>1;
  const share = !best ? 'Nobody took a skin'
    : tied ? 'Skins finished all square'
    : `${fn1(best.name)} took ${best.skins} skin${best.skins===1?'':'s'}${val>0?`, $${best.skins*val}`:''}`;
  return { game:'skins', stake:val, thru:sk.thru, carried_died:died,
    players:LIVE.map((p,i)=>({name:p.n, skins:sk.won[i], pts:sk.pts[i]})),
    transfers:settleTransfers(sk.pts, val),
    story:`Skins: ${line}${val>0?` · $${val} a skin`:''}${died?` · ${died} skin${died===1?'':'s'} went unclaimed`:''}`, share };
```

**Why** 'carried died' is raw engine phrasing for a carry-over expiring — unreadable to anyone who did not build the feature — so it is rewritten on the board too ('2 skins went unclaimed') and dropped from the message entirely. The share names a winner instead of listing counts: 'Jerecho took 3 skins, $30' is 25 chars with money, 20 without. `fn1()` on the leader only. A genuine tie at the top says so rather than crowning whichever name happened to sort first.

### `index.html`:7224 — confusing  (78 → 24 chars)

**Now**

```
Round robin: Jerecho Fischbeck 3-0, Jade 2-1, Will 1-2, Isaak 0-3 · $5 a match
```

**Proposed**

```
Jerecho won the day, 3-0
```

**Source**

```js
  const ord=rec.map((r,i)=>({d:r.w-r.l,i})).sort((a,b)=>b.d-a.d);
  const tie=ord[1] && ord[1].d===ord[0].d;
  const share = (tie || ord[0].d<=0) ? 'Nobody ran the table'
    : `${fn1(LIVE[ord[0].i]?.n)} won the day, ${rec[ord[0].i].w}-${rec[ord[0].i].l}`;
  return { game:'match', mode:'solo', stake,
    players:LIVE.map((p,i)=>({name:p.n, w:rec[i].w, l:rec[i].l, h:rec[i].h})),
    pairs:pairs.map(p=>({a:LIVE[p.i]?.n, b:LIVE[p.j]?.n, up:p.a-p.b, thru:p.played})),
    story:`Round robin: ${line}${stake>0?` · $${stake} a match`:''}`, share };
```

**Why** Four W-L records in a row is a league table, not a message; the winner was inferable only by parsing left to right. `share` names him and gives his record. Deliberately carries NO money: unlike match and Sunningdale Rules, no settlement figure is computed in this builder — only the per-match rate — and a message must never guess at what someone owes; the page holds the pairings and the settlement. 'Round robin:' stays on the board row, where a mode label earns its place, and goes from the message, where 13 chars before a name is a third of the budget.

### `index.html`:5276 — confusing  (115 → 36 chars)

**Now**

```
title: "Cup Season", text: "Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units", url: "https://cupseason.app/?share=9fK3xQ"
```

**Proposed**

```
title: "The settlement", text: "Jerecho & Jade beat Will & Isaak 3&2", url: "https://cupseason.app/?share=9fK3xQ"
```

**Source**

```js
    /* one line, one clause, ASCII — the page carries the detail. The cap is the
       surface's length policy, enforced once for all three link kinds. */
    const SHARE_TITLE = { settlement:'The settlement', round:'The round', recap:'The season' };
    const body = String(text||'').replace(/\s+/g,' ').trim().slice(0,70);
    if(navigator.share){
      try{ await navigator.share({ title: SHARE_TITLE[kind] || 'Cup Season', text: body, url }); return; }
      catch(e){ if(e && e.name==='AbortError') return; }
    }
```

**Why** This is the one chokepoint all three link kinds pass through and it enforced nothing — so the length discipline lives here, not in each caller. `title:'Cup Season'` was a constant across settlement, round and season recap: in any target that surfaces title, an invite and a result announced themselves identically, and the one chance to name the artifact went to the product name the recipient can already read in the URL. Per-kind titles cost three words. The url stays in its own field, which is what keeps the body ASCII-only and stops the receiving app re-packaging text and link together — the garbling the owner saw. char counts are of the `text` body.

### `index.html`:5280 — confusing  (152 → 72 chars)

**Now**

```
clipboard: "Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units: https://cupseason.app/?share=9fK3xQ"  ·  toast: "Link copied — no account needed to view it"
```

**Proposed**

```
clipboard: "Jerecho & Jade beat Will & Isaak 3&2\nhttps://cupseason.app/?share=9fK3xQ"  ·  toast: "Link copied. Paste it in the thread."
```

**Source**

```js
await navigator.clipboard?.writeText((body ? body + '\n' : '') + url);
    toast('Link copied. Paste it in the thread.');
```

**Why** The `+ ': ' +` splice produced '…6 units: https://…' — a colon after a noun, which reads as broken punctuation and visually fuses the URL into the sentence (it is also where a non-ASCII body ends up adjacent to a bare URL, exactly the shape that came back percent-encoded). A newline separates them the way a person would, and every message client linkifies a URL sitting on its own line. Uses the `body` computed at 5276 so the desktop path inherits the same 70-char discipline as the share sheet. The toast drops 'no account needed to view it': that reassurance already sits on the button the user just tapped ('Share the settlement — no account needed'), so repeating it at the moment of copying spends the confirmation on a growth talking point instead of saying what the user now holds and what to do with it. char counts are the clipboard payload.

### `index.html`:5363 — confusing  (62 → 48 chars)

**Now**

```
Jerecho Fischbeck — 90 at Arizona Biltmore CC — Links · Copper
```

**Proposed**

```
90 at Arizona Biltmore CC, beat my number by 2.0
```

**Source**

```js
/* hoist next to theirs() at 5132 — the golfer sharing their OWN round speaks
   in the first person; theirs() is for surfaces showing someone else's:
     const mine = s => String(s||'').replace(/\bYour\b/g,'My').replace(/\byour\b/g,'my');
   and courseLabel() (6135) builds '<club> — <course>', so strip the tail before
   interpolating into a sentence:
     const clubOnly = c => String(c||'').split(' — ')[0] || 'the course';  */
if(lk) lk.addEventListener('click',()=>{
  const sane = epi.pvi!=null && isFinite(epi.pvi) && Math.abs(Number(epi.pvi))<=30;
  csShareLink('round', roundId,
    `${epi.gross} at ${clubOnly(course)}${sane?`, ${mine(vsPhrase(Number(epi.pvi)))}`:''}`);
});
```

**Why** Three fixes. (1) DOUBLE EM DASH: the template's own ' — ' met courseLabel()'s, rendering 'Jerecho Fischbeck — 90 at Arizona Biltmore CC — Links · Copper'; `clubOnly()` takes the club and lets the page name the specific eighteen, and ', ' replaces the separator so no user/API-sourced label can collide with the punctuation again. (2) NO RESULT: '90' alone means nothing to a friend who does not know Jerecho's number — `epi.pvi` was sitting in scope unused, and `vsPhrase()` (5121) is the app's one phrase producer. (3) NAME: the leading full legal name is dropped entirely rather than reduced — the sharer IS the golfer and the recipient's phone already shows who sent it, so the name is the one fact this message does not have to buy. That also makes 'my number' correct here; `mine()` is the first-person mirror of `theirs()`, and the |pvi|<=30 gate is the same sanity gate recapText and drawRecapCard already apply, so a rating-less post cannot ship '71.6 over my number'.

### `index.html`:5234 — confusing  (32 → 37 chars)

**Now**

```
Card downloaded · caption copied
```

**Proposed**

```
Card saved, words copied. Paste both.
```

**Source**

```js
try{ await navigator.clipboard?.writeText(text); toast('Card saved, words copied. Paste both.'); }
    catch(e){ toast('Card saved to your downloads'); }
```

**Why** 'caption' is app-internal vocabulary — the user asked to share a card, not to be handed a caption. The ' · ' was doing conjunction duty in a two-clause status line where a person reads a comma. Most importantly this fires at the exact moment the user's two artifacts land in two different places (file system and clipboard) and the old string never said what to do about it; 'Paste both.' is the missing instruction and costs five chars. Slightly longer than the original on purpose — this is an in-app toast, not outbound text, so the ~60-char share discipline does not apply, clarity does. The catch branch stops saying 'downloaded' (a browser word) for 'saved to your downloads' (a place). Duplicated verbatim at 10662 for the major card — apply the same replacement there.

### `index.html`:11943 — confusing  (72 → 60 chars)

**Now**

```
clipboard: "You're invited to PIGL on Cup Season: https://cupseason.app/?join=PIGL26"  ·  toast: "Invite link copied: text it to the group"
```

**Proposed**

```
clipboard: "Jerecho wants you in PIGL\nhttps://cupseason.app/?join=PIGL26"  ·  toast: "Invite copied. Paste it to the crew."
```

**Source**

```js
await navigator.clipboard.writeText(text + '\n' + url);
    toast('Invite copied. Paste it to the crew.');
  } catch(e){ toast('Copy this: ' + url); }
```

**Why** Second copy of the `+ ': ' +` splice from 5280 — 'on Cup Season: https://…' reads as a broken sentence rather than a message plus a link; a newline is how a person separates them and how every client linkifies. The toast used a colon as an instruction separator, so the user read two facts jammed together; a period makes it a confirmation followed by a next step. 'the group' becomes 'the crew', the app's own vocabulary. The catch branch is the real repair: it handed over a 6-7 character code and NO link when the clipboard write failed, downgrading the shareable artifact to something the recipient must type into a screen they have never seen — it now shows the URL itself, which the user can select by hand even when the clipboard is unavailable. char counts are the clipboard payload.

### `index.html`:7973 — confusing  (65 → 100 chars)

**Now**

```
clipboard: "https://cupseason.app/?claim=a41f9c2e-77b3-4d0e-9c11-8ee2f0b6a5d7"  ·  row: "GUEST RECAP — SHARE THE LINK"  ·  button: "Copy"  ·  toast: "Recap link copied"
```

**Proposed**

```
clipboard: "Will, your card from today is here\nhttps://cupseason.app/?claim=a41f9c2e-77b3-4d0e-9c11-8ee2f0b6a5d7"  ·  row: "THEIR CARD — SEND IT TO THEM"  ·  button: "Copy link"  ·  toast: "Copied. Paste it to Will."
```

**Source**

```js
guests.forEach(g=>{ const url=`${location.origin}/?claim=${g.claim_token}`;
    const first=fn1(g.name)||'there';
    /* the link goes TO the guest, so the message addresses them — a bare UUID
       in a thread reads as spam, and this is the growth seam */
    const msg=`${first}, your card from today is here\n${url}`;
    rows.push(`<div class="check"><span class="num">🎟️</span><div class="tt"><b>${esc(g.name||'Guest')}</b><small>THEIR CARD — SEND IT TO THEM</small></div><button class="mini" data-copylink="${esc(msg)}" data-copyname="${esc(first)}" style="flex:none">Copy link</button></div>`); });

/* and the handler at 7982: */
document.querySelectorAll('#shBody [data-copylink]').forEach(b=>b.addEventListener('click',()=>{
    try{ navigator.clipboard?.writeText(b.dataset.copylink); toast(`Copied. Paste it to ${b.dataset.copyname}.`); }
    catch(_){ toast('Copy failed'); }
  }));
```

**Why** The copied payload was a naked URL with a raw UUID and zero words — pasted into a thread it looks like spam, and the recipient has no idea it is their own round from today. This is the app's primary growth seam shipping its least persuasive possible artifact, and the only share on the surface that deliberately bundles no text. The message addresses the guest by first name because the link goes to them, not about them. It deliberately says only what the payload can prove: `finish_live_round` returns guests as `{name, claim_token}` only (migration 20260716140000, line 86) — no gross, no course — and `state.live` is reset at 7932 before showLiveRecap runs, so the score and course are not safely in scope. 'GUEST RECAP — SHARE THE LINK' shouted at the sharer without saying whose card it is; 'Copy' never said copy what; the toast never said what to do next. char counts are the clipboard payload.

### `index.html`:6041 — confusing  (65 → 111 chars)

**Now**

```
clipboard: "https://cupseason.app/?claim=63b0e18a-5c44-42a7-b7a9-1d9c7e2f4488"  ·  button: "Copied ✓"
```

**Proposed**

```
clipboard: "Will, here's your 88 from Arizona Biltmore CC\nhttps://cupseason.app/?claim=63b0e18a-5c44-42a7-b7a9-1d9c7e2f4488"  ·  button: "Copied — send it to Will"
```

**Source**

```js
const first=fn1(p.name)||'there';
      /* p.name, p.total and ctx.course_label are all in scope at 6018-6036 —
         put them on the clipboard, or the poster has to invent the message
         (which is why they don't send it) */
      const where=clubOnly(ctx.course_label);
      await navigator.clipboard?.writeText(
        `${first}, here's your ${p.total||'card'}${where?` from ${where}`:''}\n${location.origin}/?claim=${p._token}`);
      b.textContent=`Copied — send it to ${first}`;
```

**Why** Second naked-UUID payload. Everything needed to make it a message was already sitting in scope at the copy site — `p.name`, `p.total`, `ctx.course_label` — and none of it reached the clipboard. The sheet's own copy at 6022 tells the poster what the LINK does ('one tap and the round lands on their own golfer card') but hands them no words to send with it, so they have to compose the message themselves at the exact moment their attention is lowest. 'Copied ✓' was a state change with no next step; naming the recipient turns it into an instruction. `clubOnly()` strips courseLabel()'s ' — <course>' tail so the sentence stays short and free of the separator collision. Degrades cleanly when the scan read no total ("here's your card"). char counts are the clipboard payload.

### `index.html`:14889 — wordy  (38 → 29 chars)

**Now**

```
PIGL on Cup Season — the season so far
```

**Proposed**

```
Kachinas on top in PIGL by 14
```

**Source**

```js
  /* teams[] (3363) is refilled and sorted by points in loadStandingsAndFeed
     (12323-12327); solo leagues have no squads, so fall back to indRows. */
  const T = (typeof teams!=='undefined' && teams.length) ? teams : (window.indRows||[]);
  const gap = T.length>1 ? Math.round(T[0].pts - T[1].pts) : 0;
  const lead = !T.length ? `${CS.league?.name || 'Our league'} standings`
    : gap>0 ? `${T[0].name || fn1(T[0].n)} on top in ${CS.league?.name||'the season'} by ${gap}`
    : `It is tied at the top in ${CS.league?.name || 'the season'}`;
  window.csShareLink?.('recap', CS.season.id, lead);
```

**Why** Named the product instead of the news — 'on Cup Season' is marketing copy sent to people who already have the app, and 'the season so far' has no result, no leader and no number. The season page's entire subject is the standings, and the leader was already computed and sorted in `teams` long before this button could be tapped. 'on top in' rather than 'leads' sidesteps subject-verb agreement on squad names, which are sometimes plural ('Kachinas lead' vs 'Squad 4 leads'). Solo leagues fall back to `window.indRows`, whose rows carry `.n` — a full display_name — hence `fn1()` on that branch and not on squad names. A genuine tie says so instead of claiming a lead of 0.

### `index.html`:5214 — wordy  (93 → 38 chars)

**Now**

```
90 at Arizona Biltmore CC — Links · Copper — beat their number by 2.0 · 3 pts · cupseason.app
```

**Proposed**

```
Jerecho shot 90 at Arizona Biltmore CC
```

**Source**

```js
function recapText(d){
  /* the caption's only job is to say whose card this is — the PNG already
     prints the gross (y=760), the band (y=850-906), the course (y=1084), the
     points (y=1134) and cupseason.app (y=1292). Repeating the artifact in the
     caption is rule 5 inverted. */
  return `${fn1(d.name) || 'A golfer'} shot ${d.gross} at ${clubOnly(d.course)}`;
}
```

**Why** Every fact in the old caption was already drawn on the image it was attached to — 93 chars of pure duplication — and the one thing the card had that the caption did not was the golfer's NAME, which is why 'beat their number by 2.0' read as a phrase with no antecedent. Inverting that is the whole fix: caption supplies the subject, card supplies the numbers. `fn1()` on d.name, `clubOnly()` kills the same double-em-dash collision as 5363. Dropping '· cupseason.app' loses nothing — a bare domain with no protocol is not linkified by most clients anyway. FLAGGING SEPARATELY (structural, not copy): `navigator.share({files,text})` at 5228 passes no `url`, so a card share can never produce a link preview at all. That is a direct cause of the owner's link-preview complaint on card shares, and no caption rewrite reaches it — the card share needs to mint a share token and pass `url` the way csShareLink does.

### `index.html`:11937 — wordy  (36 → 25 chars)

**Now**

```
You're invited to PIGL on Cup Season
```

**Proposed**

```
Jerecho wants you in PIGL
```

**Source**

```js
const who = fn1(CS.profile?.display_name);
  const text = who ? `${who} wants you in ${CS.league.name}`
                   : `You're in ${CS.league.name} if you want it`;
  if(navigator.share){
    try { await navigator.share({ title: 'The invite', text, url }); return; }
```

**Why** The strongest string on this surface and the model the rest were rewritten toward — one clause, url in its own field, already inside budget. Two small faults remain. The passive 'You're invited' has no actor, and the recipient's phone already shows who sent it, so the sentence spends itself on a construction the medium has made redundant; naming the sender is more information in eleven fewer characters, and 'on Cup Season' goes because the URL already says it. `CS.profile.display_name` is the full legal name, so `fn1()` applies here as everywhere. Second: `title:'Cup Season'` was identical to the settlement and season shares, so nothing distinguished an invite from a result in any target that surfaces title — 'The invite' matches the per-kind titles added at 5277.

---

## Board post stories — league feed text (client-composed game results in index.html + SQL-composed post bodies in supabase/migrations)

Every story on this surface is a data row wearing a sentence: the format label leads, the result trails, and the golfer arrives as a full legal name — often twice, often upper()'d beyond recovery. Two structural fixes carry roughly two-thirds of the rewrites on their own (a shared first-name helper on both sides of the wire, and a `headline` field split out of `story` so the share sheet stops shipping a feed row), and one item is a pure regression restore that costs nothing but a migration.

### `index.html`:7186 — broken  (115 → 56 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2. Sunningdale Rules.
```

**Source**

```js
const fn = n => (n||'').trim().split(/\s+/)[0];
const names = t => MTEAMS[t].map(i=>fn(LIVE[i]?.n)).filter(Boolean).join(' & ');
const story = `${names(winner)} beat ${names(winner===0?1:0)} ${status}. Sunningdale Rules.`;
const headline = `${names(winner)} beat ${names(winner===0?1:0)} ${status}`;
```

**Why** The exact string the owner texted. Four fixes: (a) result leads, mode name trails as a tag rather than a venue-shaped prefix — and it is now 'Sunningdale Rules', because bare 'Sunningdale:' in front of a name reads as the English course and collided with the ARIZONA BILTMORE CC footer; (b) 'def.' is wire-service, 'beat' is what a person says; (c) names(t) maps LIVE[i].n, which applyServerRound() (index.html:6859) fills from profile.display_name — take the first whitespace token, and add a last initial only when the crew has two of the same first name; (d) 'no handicaps' is a bylaw true of every Sunningdale Rules round, not news, and 'bank: … 6 units' is engine vocabulary — both belong on the settlement card, which everyone in the group already sees at finish. Add the separate `headline` key (41 chars) so csShareLink stops re-using the feed row.

### `index.html`:7238 — broken  (158 → 48 chars)

**Now**

```
Sunningdale, everyone for themselves: Jerecho Fischbeck 6, Jade Smith 5, Will Ferrell 4, Isaak Cole 3 · no handicaps · bank: Jerecho Fischbeck $30 (each owes)
```

**Proposed**

```
Jerecho took it with 6 holes. Sunningdale Rules.
```

**Source**

```js
const win = order[0];
story: `${fn(LIVE[win]?.n)} took it with ${m.wins[win]} hole${m.wins[win]===1?'':'s'}. Sunningdale Rules.`,
headline: `${fn(LIVE[win]?.n)} took it with ${m.wins[win]} holes`
```

**Why** The longest story the app can emit, and it never says who won — it prints four numbers and makes the reader compare them. `order` is already sorted descending at line 7235, so the winner is order[0] and costs nothing to name. Four full display names go to one first name; the other three players are on the card. 'no handicaps' is bylaw noise. '$30 (each owes)' is a ledger term with a parenthetical instruction stapled on — per-man liability is exactly what the settlement card is for (it is stated there by design, per the D75 comment above this function).

### `index.html`:7224 — broken  (97 → 52 chars)

**Now**

```
Round robin: Jerecho Fischbeck 2-1, Jade Smith 2-1, Will Ferrell 1-2, Isaak Cole 1-2 · $5 a match
```

**Proposed**

```
Jerecho and Jade split the round robin, 2 wins each.
```

**Source**

```js
const top = Math.max(...rec.map(r=>r.w));
const lead = LIVE.map((p,i)=>({n:fn(p.n), w:rec[i].w})).filter(x=>x.w===top);
const line = lead.length === 1
  ? `${lead[0].n} won the round robin, ${top} win${top===1?'':'s'} from ${LIVE.length-1}.`
  : `${lead.slice(0,-1).map(x=>x.n).join(', ')} and ${lead[lead.length-1].n} split the round robin, ${top} win${top===1?'':'s'} each.`;
return { …, story: line, headline: line };
```

**Why** The only item on this surface with no result at all — it is a standings table, and when two players tie at 2-1 the line does not even resolve which of them the reader should be congratulating. Naming the tie explicitly ('split it') is honest and is what the group would say. W-L triplets are a table format; they stay in the `players` array the card renders. '$5 a match' is the rate, not the outcome — the card already shows what each man owes. First names from LIVE[i].n (display_name).

### `index.html`:7858 — broken  (87 → 44 chars)

**Now**

```
Wolf: Jerecho Fischbeck +$12, Jade Smith −$4, Will Ferrell +$2, Isaak Cole −$10 · $2/pt
```

**Proposed**

```
Jerecho took Wolf, up $12. Isaak's down $10.
```

**Source**

```js
const hi = pts.indexOf(Math.max(...pts)), lo = pts.indexOf(Math.min(...pts));
const story = val > 0
  ? `${fn(LIVE[hi]?.n)} took Wolf, up $${pts[hi]*val}. ${fn(LIVE[lo]?.n)}'s down $${Math.abs(pts[lo]*val)}.`
  : `${fn(LIVE[hi]?.n)} took Wolf with ${pts[hi]} point${pts[hi]===1?'':'s'}.`;
```

**Why** Result-last: today the winner is only findable by scanning four signed numbers for the largest. Lead with him, then name the man who paid for it — that second clause is the ribbing the group actually reads, and two names is the right ration for a feed row. Drops the four-name ledger (it lives in `players` and `transfers`, which the card renders) and drops '$2/pt', which is a rate, not news. Also retires the U+2212 minus: it is a known hazard on the way out to a share sheet and there is nothing left for it to sit in. The no-money branch no longer ends on a bare ' pts' that reads as truncation.

### `index.html`:7868 — broken  (69 → 43 chars)

**Now**

```
Skins: Jerecho Fischbeck 3, Jade Smith 1 · $5 a skin · 2 carried died
```

**Proposed**

```
Jerecho took 3 skins and $15. Jade got one.
```

**Source**

```js
const top = [...winners].sort((a,b)=>b.skins-a.skins);
const story = !top.length
  ? 'Nobody won a skin all day.'
  : `${fn(top[0].name)} took ${top[0].skins} skin${top[0].skins===1?'':'s'}${val>0?` and $${top[0].skins*val}`:''}.`
    + (top[1] ? ` ${fn(top[1].name)} got ${top[1].skins===1?'one':top[1].skins}.` : '');
```

**Why** The reader learns the rate ($5 a skin) but never the money — the one number they want. Multiply it out: 3 skins at $5 is $15, said once. 'carried died' is pure engine state ('carry' and 'die' are internal names); the carry drama belongs on the card, which has room for it. Full names to first names. The empty case gets a real sentence instead of 'Skins: nobody took a skin' — which reads as a label with a shrug attached.

### `index.html`:7185 — broken  (77 → 61 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade and Will & Isaak halved it · bank empty
```

**Proposed**

```
All square — Jerecho & Jade, Will & Isaak. Sunningdale Rules.
```

**Source**

```js
story: `All square — ${names(0)}, ${names(1)}. Sunningdale Rules.`,
headline: `All square — ${names(0)}, ${names(1)}`
```

**Why** 'Jerecho Fischbeck & Jade and Will & Isaak' parses as four separate items — the '&'/'and' collision makes the sides unreadable. Leading with 'All square' is the result-first form of a halve, and it lets a comma separate the two sides so the ampersands stay unambiguously internal. 'bank empty' is engine state and was the only other content in the line. First names on both sides fixes the current sentence, which uses a full name on one side and a first name on the other. At 61 this is one over target, but it is a board line — the `headline` for the share sheet is the 41-char first clause.

### `20260726120000_match_story_override.sql`:115 — broken  (87 → 55 chars)

**Now**

```
Match play: Jerecho Fischbeck & Jade and Will & Isaak halved the match — no money moves
```

**Proposed**

```
All square — Jerecho & Jade, Will & Isaak. Nobody pays.
```

**Source**

```js
v_story := case
  when coalesce(p_result->>'side_a','') = '' or coalesce(p_result->>'side_b','') = ''
    then 'All square.' || case when v_stake > 0 then ' Nobody pays.' else '' end
  else 'All square — ' || (p_result->>'side_a') || ', ' || (p_result->>'side_b') || '.'
       || case when v_stake > 0 then ' Nobody pays.' else '' end
end;
```

**Why** Same '& … and … &' ambiguity as the Sunningdale halve, fixed the same way: result first, comma between the sides. 'no money moves' becomes 'Nobody pays' — the same fact in the group's own words. The real defect is the fallbacks: 'side A' / 'side B' would post literal placeholder text to a crew's feed, so the rewrite drops the names entirely when either is missing rather than shipping a variable name. First names arrive from the index.html:7791 fix.

### `20260712090000_round_posts_traceable.sql`:22 — broken  (58 → 32 chars)

**Now**

```
JERECHO FISCHBECK POSTED 92 GROSS · ENCANTO GC · DIFF 18.9
```

**Proposed**

```
Jerecho posted 92 at Encanto GC.
```

**Source**

```js
firstname(coalesce(p.display_name, 'A member'))
         || ' posted ' || new.gross
         || case when new.holes_played = 9 then ' for nine' else '' end
         || case when coalesce(new.course_label,'') <> ''
                 then ' at ' || new.course_label else '' end
         || '.'
```

**Why** The highest-volume string in the app and it breaks the D2 rule outright — 'DIFF 18.9' is the exact banned engine word, and the compact feed (index.html:4691) plus the quiet-day digest (4605) render this raw body, so it is visible in production today even though the full card at 4805 correctly says 'BEAT YOUR NUMBER BY 2'. Killing DIFF here fixes all three renderers at once. Dropping upper() is the other half: easeCaps can only restore a sentence opener, so 'ENCANTO GC' comes back as 'Encanto gc' and any name outside the client's registry comes back as 'Jerecho fischbeck' — store natural case and let CSS do any shouting. `firstname()` is the proposed shared SQL helper (split_part(trim(x),' ',1)) mirroring the client's; two migrations (20260716190000, 20260724230000/D66) already moved to natural case for this reason.

### `20260722100000_moment_cascade_live_expiry.sql`:131 — broken  (58 → 49 chars)

**Now**

```
JERECHO FISCHBECK SET A PERSONAL BEST — DIFF 5.2 (WAS 6.1)
```

**Proposed**

```
Jerecho set a personal best. New number to chase.
```

**Source**

```js
v_moment := v_name || ' set a personal best. New number to chase.';
-- with v_name selected in natural case (line 38) and the sentence-opener
-- capital applied once before insert:
-- v_moment := upper(left(v_moment,1)) || substr(v_moment,2);
```

**Why** Not a rewrite — a restore. 20260716190000_moment_voice.sql already shipped this exact line and its header names 'DIFF 5.2 (WAS 6.1)' as the jargon it was killing; 20260722100000 then copied the body from the PRE-voice migration (20260716020000) to add round_id and silently reverted it. Production is serving the old string. The fix is a new migration re-applying the voice text on top of the current structural body, plus reverting v_name at line 38 to natural case (moment_voice kept it deliberately so 'JT' and 'McDonald' survive). Worth a decision-log note: because every fix is a new migration carrying a full function body, any earlier voice-only pass is at risk each time someone copies the latest *structural* version rather than the latest version.

### `20260722100000_moment_cascade_live_expiry.sql`:128 — broken  (56 → 71 chars)

**Now**

```
JERECHO FISCHBECK BROKE 90 FOR THE FIRST TIME — 88 GROSS
```

**Proposed**

```
Jerecho broke 90 for the first time — an 88. That one goes on the wall.
```

**Source**

```js
v_moment := v_name || ' broke ' || v_barrier || ' for the first time — a '
         || new.gross || '. That one goes on the wall.';
```

**Why** Same regression, same restore — this is 20260716190000_moment_voice.sql:128-129 verbatim. I am deliberately not shortening it further: it is a ratified voice line, it is a board moment rather than share-sheet text, and 'That one goes on the wall' is the whole point of the post. It does run 71 chars, and because the push Edge Function fans every post by kind it will also land on a lock screen — if push truncation bites, the answer is a short `headline` on the post row, not a re-edit of a decided line. Natural case matters most here: ALL CAPS destroys the name and easeCaps cannot get it back.

### `20260722100000_moment_cascade_live_expiry.sql`:134 — broken  (46 → 68 chars)

**Now**

```
JERECHO FISCHBECK — 8 STRAIGHT WEEKS. IRON MAN
```

**Proposed**

```
Jerecho has posted 8 weeks running. Iron man doesn't take weeks off.
```

**Source**

```js
v_moment := v_name || ' has posted ' || v_streak
         || ' weeks running. Iron man doesn''t take weeks off.';
```

**Why** Third of the three reverted headlines; restored verbatim from 20260716190000_moment_voice.sql:133-134. The current form is an em-dash-as-colon construction — a data row, not a sentence — and the ALL CAPS name is unrecoverable downstream. Ships in the same restore migration as the other two.

### `20260716180000_auto_bye.sql`:86 — broken  (34 → 60 chars)

**Now**

```
FLOOR MISSED — 5 PTS OFF THE BOARD
```

**Proposed**

```
Jerecho was short on rounds in July. 5 points off the squad.
```

**Source**

```js
-- hoist the v_name select above the branch (it currently lives only in the
-- bye arm, 8 lines up) so both penalty arms can use it
insert into posts (league_id, season_id, kind, member_id, body)
values (se.league_id, p_season, 'system', m.member_id,
        firstname(coalesce(v_name,'A golfer'))||' was short on rounds in '
        ||to_char(p_month,'FMMonth')||'. '||abs(delta)||' points off the squad.');
```

**Why** The whole crew reads a penalty post and cannot tell whose it is — the name is already in scope eight lines up (selected for the bye branch) and simply is not used. That is a §16 violation more than a wording one: a points figure with no path to what produced it. 'FLOOR' is bylaw shorthand with no antecedent in the sentence, so say the plain thing that happened. 'OFF THE BOARD' is ambiguous between the leaderboard and the squad total — it is the squad total, so say squad. Naming the month gives the reader the receipt; member_id on the post gives the client a tap target into the ledger row that carries the full reason.

### `20260716180000_auto_bye.sql`:97 — broken  (31 → 50 chars)

**Now**

```
MONTH FORFEITED — 42 PTS STRUCK
```

**Proposed**

```
Jerecho loses July — 42 points, not enough rounds.
```

**Source**

```js
insert into posts (league_id, season_id, kind, member_id, body)
values (se.league_id, p_season, 'system', m.member_id,
        firstname(coalesce(v_name,'A golfer'))||' loses '
        ||to_char(p_month,'FMMonth')||' — '||m.counting_pts
        ||' points, not enough rounds.');
```

**Why** The single harshest event in a season — a whole month of somebody's points erased — and the post does not say whose, does not name the month, and gives no reason. 'STRUCK' is ledger vocabulary. Same v_name hoist as the deduct branch; same member_id stamp so the post is traceable back to the season_adjustments row that carries the full 'Floor N/mo — posted M · bye already used' explanation. This is the one post on the surface where showing its work is not optional.

### `20260716160000_ryder_slice3.sql`:183 — broken  (122 → 37 chars)

**Now**

```
SESSION 2: JERECHO FISCHBECK DEF. WILL FERRELL +2.3/-1.1 · JADE SMITH DEF. ISAAK COLE +0.4/NO ROUND · MUDSHARKS LEAD 4½–3½
```

**Proposed**

```
Mudsharks lead 4½–3½ after session 2.
```

**Source**

```js
-- one post per duel, natural case, PvI spoken through mj_vs()
for d in (select ... from event_duels ... where session_id = p_session order by id) loop
  perform event_post(v_event, d.win_name||' beat '||d.lose_name||', '||mj_vs(d.win_pvi)||' to '||mj_vs(d.lose_pvi)||'.');
end loop;
v_score := case when pa = pb then 'All square, '||evhalf(pa)||'–'||evhalf(pb)
                when pa > pb then v_na||' lead '||evhalf(pa)||'–'||evhalf(pb)
                else v_nb||' lead '||evhalf(pb)||'–'||evhalf(pa) end;
perform event_post(v_event, v_score||' after session '||v_no||'.');
```

**Why** Every duel concatenated into one 400-char-capped post: a 6-a-side session truncates mid-name with no warning, and the running scoreline — the only thing most readers want — is last, behind the wall. Split it: the scoreline is its own post (this rewrite), each duel is its own post so a player can find himself. '+2.3/-1.1' is raw PvI, the banned engine number printed as a fraction; mj_vs() (the_major.sql:113) already converts PvI into spoken grammar and is the one good voice helper in the SQL layer — it just needs natural case and this second adoption. 'SESSION 2:' leading with an internal index moves to a trailing 'after session 2'. Names: first-name via firstname() on display_name, no upper().

### `20260716160000_ryder_slice3.sql`:242 — broken  (77 → 56 chars)

**Now**

```
THE DESERT CUP: MUDSHARKS TAKE THE CUP 7½–4½ · MVP: JERECHO FISCHBECK (3-0-1)
```

**Proposed**

```
Mudsharks take the Desert Cup 7½–4½. Jerecho won 3 of 4.
```

**Source**

```js
perform event_post(v_event,
  case when v_win is null
       then 'The '||v_ename||' is shared — '||v_na||' and '||v_nb||', '||evhalf(pa)||'–'||evhalf(pb)||'.'
       when v_win = v_ta
       then v_na||' take the '||v_ename||' '||evhalf(pa)||'–'||evhalf(pb)||'.'
       else v_nb||' take the '||v_ename||' '||evhalf(pb)||'–'||evhalf(pa)||'.' end
  || coalesce(' '||firstname(mvp_name)||' won '||mvp_w||' of '||mvp_played||'.', ''));
```

**Why** The single most shareable moment the Ryder produces, and it reads like a wire-service ticker: the event name leads, the result is second, and the MVP arrives as a full upper()'d name trailed by '(3-0-1)' — a standings triplet that needs a legend. Fold the event name into the winning clause so the result leads and the cup is still named. 'won 3 of 4' is the same claim in words anyone reads; the triplet stays on the scoreboard where the column headers explain it. Natural case throughout — 'MUDSHARKS' comes back from easeCaps intact only by luck of the registry.

### `20260720193000_the_major.sql`:522 — broken  (151 → 54 chars)

**Now**

```
THE SUMMER JUG — CHAMPION: JERECHO FISCHBECK (88, 4.2 UNDER) · RUNNER-UP: WILL FERRELL 1.1 UNDER · THIRD: JADE SMITH LEVEL · POT $120 — WINNER TAKES IT
```

**Proposed**

```
Jerecho takes the Summer Jug, 4.2 under. And the $120.
```

**Source**

```js
v_line := firstname(v_champ.display_name)||' takes the '||s.name||', '||mj_vs(v_champ.pvi)||'.'
  || case when v_pot > 0 and s.pot_split = 'wta' then ' And the '||mj_money(v_pot)||'.'
          when v_pot > 0 then ' '||mj_money(v_pot)||' in the pot.'
          else '' end
  || v_tie;
-- mj_vs() returns natural case: 'under' / 'over' / 'level' / 'no card'
```

**Why** 150 chars and five ' · ' segments — an entire leaderboard transcribed into one post, with 'CHAMPION:' / 'RUNNER-UP:' / 'THIRD:' as results-table labels. The podium is page content; the message names the champion and the money. mj_vs() is the right idea already in the file — it just needs to come out of the parentheses (where it sat next to a gross, competing for the reader) and into the sentence, in natural case. Three full upper()'d display names go to one first name. The gross drops: '4.2 under' is the Major's own measure and the gross is on the card.

### `index.html`:7957 — broken  (57 → 20 chars)

**Now**

```
WILL & ISAAK PAYS JERECHO FISCHBECK & JADE $5 · SETTLE UP
```

**Proposed**

```
Will & Isaak owe $5.
```

**Source**

```js
const money = result.stake>0
  ? (won ? `${lSide} owe $${result.stake}.` : 'All square. No money moves.')
  : 'Bragging rights only.';
```

**Why** Grammar bug first: a two-man side takes 'PAYS', so every team game renders 'Will & Isaak pays'. 'owe' is correct for one man or two and needs no branch. The winner is already the bold line directly above this one, so repeating both sides in the money line is duplication — the debt alone is the missing fact. 'SETTLE UP' is an instruction shouted at people who just watched it happen. Drop the .toUpperCase() calls: this is the one surface where the winner's name should read largest, and it is where it is most mangled — let CSS do the shouting, as it already does for the sibling rows.

### `index.html`:7965 — broken  (83 → 23 chars)

**Now**

```
ISAAK COLE PAYS JERECHO FISCHBECK $10 · JADE SMITH PAYS WILL FERRELL $4 · SETTLE UP
```

**Proposed**

```
Isaak owes Jerecho $10.
```

**Source**

```js
const tx = result.transfers || [];
const money = result.stake>0
  ? (tx.length === 1 ? `${fn(tx[0].from)} owes ${fn(tx[0].to)} $${tx[0].amt}.`
     : tx.length ? `${tx.length} payments to settle.` : 'All square. No money moves.')
  : 'Bragging rights only.';
// each transfer then renders as its own row beneath, first names, natural case:
// tx.forEach(t=>rows.push(`<div class="check">…${fn(t.from)} owes ${fn(t.to)} $${t.amt}…</div>`));
```

**Why** A 4-man Wolf produces up to three transfers and this concatenates all of them into one headline — 120+ chars with two upper()'d full names per transfer. Transfers are a settlement table: one payment reads fine as a sentence, more than one belongs in rows where each payer can find his own. The count line ('2 payments to settle') is honest and points at the rows directly beneath it. First names via the shared helper; drop .toUpperCase().

### `index.html`:7986 — broken  (147 → 67 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units: https://cupseason.app/?share=x
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2
https://cupseason.app/?share=x
```

**Source**

```js
document.getElementById('lrShareLink')?.addEventListener('click',()=>csShareLink('settlement', lrId,
  (result?.headline || result?.story || 'Settled on the course').slice(0,70)));

// and at index.html:5280, stop punctuating the join:
await navigator.clipboard?.writeText((text ? text + '\n' : '') + url);
```

**Why** This is the line that produced the owner's text. Three defects, all structural: (a) the board story IS the share text — one string doing two jobs, with .slice(0,120) as the only editorial control, which is why the message read like a feed row (it is one); (b) 120 is double the target and the slice can cut mid-name; (c) csShareLink at index.html:5280 joins with ': ', producing '… 6 units: https://…' — a colon after a sentence. Reading `result.headline` first inverts principle 5: the message hooks, the page proves. finish_live_round already stores p_result as jsonb in live_rounds.game_result, so a second key costs nothing schema-wise and the existing deploy-skew retry covers the rollout — an old client falls back to `story`, a new one prefers `headline`. The newline join is what a person actually sends. Separately and out of scope for copy: the link preview still shows the static og-image.png (allowlisted in stamp-version.sh), so the card can never carry the result — that needs a per-share OG endpoint, which is the other half of the owner's complaint.

### `20260724120000_forfeit_ledger.sql`:85 — broken  (99 → 66 chars)

**Now**

```
STAKE POSTED: FIRST TO BREAK 80 — JERECHO FISCHBECK VS WILL FERRELL · LOSER BUYS DINNER AT THE TURN
```

**Proposed**

```
Jerecho v Will — first to break 80. Loser buys dinner at the turn.
```

**Source**

```js
select firstname(display_name) into v_a from profiles where id = auth.uid();
select firstname(display_name) into v_b from profiles where id = p_other;
insert into posts (league_id, kind, body)
values (p_league, 'system',
  v_a || case when v_b is not null then ' v ' || v_b else ' v the field' end
  || ' — ' || v_name || '. ' || v_terms);
```

**Why** The worst casing damage on the surface: upper() is applied to two full display names AND to v_name, and the neighbouring context drags the user's own v_terms prose through easeCaps too — the app rewrites the words a member typed. Stop upper()-ing entirely and both survive. 'STAKE POSTED:' is a database event name standing where the people should; leading with the two names makes it a challenge, which is what it is. The terms clause is the fun part and earns its characters, so it stays — but note it is user-supplied and length-variable (capped at 200 in the insert above), which is the real argument for keeping every other segment tight.

### `00000000000000_initial_baseline.sql`:508 — broken  (41 → 36 chars)

**Now**

```
MUDSHARKS DRAFTS JERECHO FISCHBECK · R2P3
```

**Proposed**

```
Mudsharks take Jerecho with pick 11.
```

**Source**

```js
insert into posts (league_id, season_id, kind, body)
select se.league_id, d.season_id, 'system',
       s.name || ' take ' || firstname(p.display_name)
       || ' with pick ' || d.current_pick || '.'
from squads s, league_members lm join profiles p on p.id = lm.profile_id
where s.id = squad and lm.id = p_member;
```

**Why** 'R2P3' is round/pick shorthand that easeCaps mangles into 'R2p3' — visible nonsense in the feed, and the overall pick number is the thing people actually track anyway (d.current_pick is already read two lines above). 'MUDSHARKS DRAFTS' pairs a plural squad name with a singular verb; 'take' is right for both and is what a draft room says. Full upper()'d display name to a first name — this post fires once per pick, so it is also one of the highest-volume strings in a draft.

### `20260726120000_match_story_override.sql`:119 — confusing  (75 → 48 chars)

**Now**

```
Match play: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · $5 on the line
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2. That's $5.
```

**Source**

```js
v_story := coalesce(case when (p_result->>'winner')='0' then p_result->>'side_a' else p_result->>'side_b' end, 'The winners')
        || ' beat '
        || coalesce(case when (p_result->>'winner')='0' then p_result->>'side_b' else p_result->>'side_a' end, 'the other side')
        || ' ' || coalesce(p_result->>'status','')
        || case when v_stake > 0 then '. That''s $' || v_stake || '.' else '.' end;
```

**Why** 'Match play:' is a format label standing where the result should. '$5 on the line' is pre-round framing posted after the round is over — past tense, and it should point at the money that actually moved. The names are not fixable here: side_a/side_b arrive already joined from index.html:7791, where names() maps LIVE[i].n (display_name) through ' & '. Fix it at that call site with the first-name helper and this string inherits it — which is also why the two layers must agree on one helper rather than each growing its own.

### `20260720193000_the_major.sql`:659 — confusing  (70 → 44 chars)

**Now**

```
JERECHO FISCHBECK OPENS WITH 88 — 4.2 UNDER · TAKES THE CLUBHOUSE LEAD
```

**Proposed**

```
Jerecho leads the clubhouse — 88, 4.2 under.
```

**Source**

```js
v_nm := firstname(coalesce(v_name,'A golfer'));
if m.exhibition then
  v_line := v_nm||' posts '||new.gross||', '||mj_vs(v_pvi)||'. Exhibition.';
elsif v_lead is null or v_pvi > v_lead then
  v_line := v_nm||' leads the clubhouse — '||new.gross||', '||mj_vs(v_pvi)||'.';
elsif v_pvi = v_lead then
  v_line := v_nm||' ties the lead — '||new.gross||', '||mj_vs(v_pvi)||'.';
else
  v_line := v_nm||' posts '||new.gross||', '||mj_vs(v_pvi)||'. Leader''s at '||mj_vs(v_lead)||'.';
end if;
```

**Why** The lead change is the news and it is appended last, behind the score — invert it so the clause that changed the tournament leads. 'IMPROVES TO' is a database verb; restructuring around the lead state removes the need for it entirely. Full upper()'d display name to a first name. mj_vs() in natural case so 'under' stops shouting.

### `index.html`:15285 — confusing  (46 → 36 chars)

**Now**

```
Jerecho Fischbeck & Jade def. Will & Isaak 3&2
```

**Proposed**

```
Jerecho & Jade beat Will & Isaak 3&2
```

**Source**

```js
const story = r.story
  || (r.winner != null && r.side_a && r.side_b
      ? `${r.winner === '0' ? r.side_a : r.side_b} beat ${r.winner === '0' ? r.side_b : r.side_a} ${r.status || ''}`.trim()
      : (r.side_a && r.side_b ? `All square — ${r.side_a}, ${r.side_b}` : 'Settled on the course'));
```

**Why** This is the page a non-member lands on from the text message, and it sets the same string in 26px serif that the message already showed them — the link adds no legibility, it repeats. Once r.story is short and first-named (items 1-8), the normal path here is fixed by construction, which is the argument for fixing the composers rather than patching the page. Two things still need fixing here: 'def.' matches the composers' new 'beat', and the fallback literals 'Winners' / 'the other side' would ship placeholder text to a stranger's screen — guard on the names being present and fall through to the existing 'Settled on the course' instead. Note the division of labour: this page should render the fuller `story` (it is the proof, and the players table sits under it); only the share message uses the short `headline`.

### `20260724120000_forfeit_ledger.sql`:125 — confusing  (93 → 41 chars)

**Now**

```
STAKE SETTLED: FIRST TO BREAK 80 — JERECHO FISCHBECK TAKES IT · LOSER BUYS DINNER AT THE TURN
```

**Proposed**

```
Jerecho wins the bet — first to break 80.
```

**Source**

```js
select firstname(display_name) into v_w from profiles where id = p_winner;
v_line := v_w || ' wins the bet — ' || f.name || '.';
insert into posts (league_id, kind, body) values (f.league_id, 'system', left(v_line,400));
```

**Why** The winner is third in the sentence, behind a status label and the stake's own name. The terms are repeated verbatim from the posting post — the crew already read them, and the stake card still carries them. Full upper()'d display name to a first name, natural case so f.name (user-written) survives.

### `20260716120000_index_starter_guard.sql`:100 — confusing  (68 → 43 chars)

**Now**

```
JERECHO FISCHBECK'S NUMBER NOW COMES FROM THEIR SCORES — 12.4 → 11.8
```

**Proposed**

```
Jerecho's scores set the number now — 11.8.
```

**Source**

```js
insert into posts (league_id, kind, member_id, body)
select lm.league_id, 'system', lm.id,
       firstname(coalesce(v_name, 'A golfer')) || '''s scores set the number now — ' || v_auto || '.'
  from league_members lm where lm.profile_id = new.profile_id;
```

**Why** A possessive on an upper()'d full name is the exact shape easeCaps's own comment (index.html:4173) cites as unrecoverable — natural case plus a first name removes the problem rather than asking the client to repair it. 'THEIR' after a named subject reads as a third party; restructuring around 'Jerecho's scores' as the subject drops the pronoun entirely instead of guessing at gender. '12.4 → 11.8' is arrow-notation diff, not a sentence — the new number is the news, and the prior value is already on the profile and in the receipt.

### `20260716160000_ryder_slice3.sql`:95 — wordy  (80 → 46 chars)

**Now**

```
SESSION 2 PAIRINGS: JERECHO FISCHBECK VS WILL FERRELL · JADE SMITH VS ISAAK COLE
```

**Proposed**

```
Session 2 is up: Jerecho v Will, Jade v Isaak.
```

**Source**

```js
select string_agg(firstname(pa.display_name)||' v '||firstname(pb.display_name), ', ')
  into v_lines from event_duels d ... where d.session_id = p_session;
perform event_post(v_event,
  case when v_pairs <= 3
       then 'Session '||v_no||' is up: '||v_lines||'.'
       else 'Session '||v_no||' is up. '||v_pairs||' duels on the sheet.' end);
```

**Why** Full display names on both sides of every 'VS', and the 400-char cap will eat the tail of a large field silently. First names roughly halve it; the ≤3 guard means the line never grows past a sentence — a big league gets the count and taps through rather than getting a truncated slate. 'PAIRINGS' is organizer vocabulary; the crew says 'you're on Will', so 'is up' and a plain 'v' do the work. Natural case, no upper().

### `20260724230000_season_result_columns.sql`:182 — wordy  (111 → 56 chars)

**Now**

```
Season complete: Mudsharks take the Cup 210–187 · tiebreak: fewest rounds used · Points king: Jerecho Fischbeck
```

**Proposed**

```
Mudsharks take the Cup, 210–187. Jerecho is points king.
```

**Source**

```js
v_story := coalesce(v_champname,'The champion')
  || case when v_cup then ' take the Cup Final' else ' take the Cup' end
  || case when v_score2 is not null then ', ' || v_score1 || '–' || v_score2 else '' end
  || '.'
  || case when v_kname <> '' then ' ' || firstname(v_kname) || ' is points king.' else '' end;
```

**Why** The best-voiced string in the SQL layer — natural case already, per D66 — and still three clauses deep with a bylaw in the middle of the champion's sentence. 'Season complete:' is a status label standing in front of the champion; drop it and the champion leads, which is the whole point of the post. 'tiebreak: fewest rounds used' is machinery: it belongs on the standings page next to the ladder it came from, where §14.3 can actually be shown. 'Points king' stays — it is a real award name in the product, not engine vocabulary — but it becomes a sentence rather than a label, and v_kname (a display_name) takes the first token.

### `20260724230000_season_result_columns.sql`:191 — wordy  (90 → 50 chars)

**Now**

```
The pot: $480 — champs $288 · runner-up $144 · points king $48 · settle between yourselves
```

**Proposed**

```
Mudsharks take $288. Settle up between yourselves.
```

**Source**

```js
insert into posts (league_id, season_id, kind, body)
values (se.league_id, p_season, 'system',
  coalesce(v_champname,'The champions')||' take $'||round(pot * st.payout_champ / 100.0)
  ||'. Settle up between yourselves.');
```

**Why** 89 chars of payout table with no names in it — the reader learns three amounts and cannot tell who to pay. v_champname is already in scope in this function (selected at line 170 for the story post), so naming the winner costs nothing. The full split is page content: it is a table, it has three rows, and the ledger renders it properly. 'settle between yourselves' is the money instruction and it currently sits fourth, after three dollar figures — it moves up to where an instruction belongs.

### `20260715230000_tee_time.sql`:77 — wordy  (124 → 48 chars)

**Now**

```
JERECHO FISCHBECK PUT A ROUND ON THE BOOKS — SAT AUG 09 · 7:40AM · ENCANTO GC · WITH JADE SMITH & WILL FERRELL · "tee it up"
```

**Proposed**

```
Jerecho is playing Encanto GC Sat Aug 9, 7:40am.
```

**Source**

```js
select firstname(coalesce(display_name, 'A golfer')) into v_name
  from profiles where id = auth.uid();
insert into posts (league_id, kind, member_id, body)
select lm.league_id, 'system', lm.id,
       v_name || ' is playing'
       || coalesce(' ' || v_course, '')
       || ' ' || to_char(p_play_on, 'FMDy FMMon FMDD')
       || coalesce(', ' || to_char(p_tee, 'FMHH12:MIam'), '')
       || '.'
  from league_members lm where lm.profile_id = auth.uid();
```

**Why** 123 chars across five segments — the longest routine post in the app. Every name in it is an upper()'d display_name (v_name and the tagged golfers, built at tee_time.sql:70-73), and the user's own note is wrapped in quotes inside an ALL CAPS sentence, so easeCaps lowercases their words. 'PUT A ROUND ON THE BOOKS' is app vocabulary where 'is playing' is what a person says. Tagged partners and the note move to the schedule card — the tags still drive the notification, they just stop being recited in the feed line, which is what kept it growing with the size of the group.

### `20260722210000_squad_formation_integrity.sql`:87 — wordy  (82 → 39 chars)

**Now**

```
SQUADS DRAWN — THE HAT HAS SPOKEN. MUDSHARKS — 3 GOLFERS · SANDBAGGERS — 3 GOLFERS
```

**Proposed**

```
The hat has spoken — your squad is set.
```

**Source**

```js
insert into posts (league_id, season_id, kind, body)
values (se.league_id, p_season, 'system',
        'The hat has spoken — your squad is set.');
```

**Why** Correction to the inventory: `reveal` is built at line 79 as squad name + headcount ('MUDSHARKS — 3 GOLFERS · SANDBAGGERS — 3 GOLFERS'), not a roster dump — so the ALL CAPS full names are not actually here. What is here is real: the line still grows one segment per squad, and a headcount is not news to anyone who just got drafted. 'THE HAT HAS SPOKEN' is good voice sitting in front of a data table; keep it, drop the table, and let the formation screen show who landed where. Natural case so the squad names on that screen are not the client's problem to restore.

### `20260716170000_endgame_dial.sql`:57 — wordy  (83 → 50 chars)

**Now**

```
THE PRO SET THE FINISH: THE CUP FINAL — FINAL 4 WEEKS, SCORED FRESH, TOP SEEDS ONLY
```

**Proposed**

```
The Pro called it: the season ends in a Cup Final.
```

**Source**

```js
insert into posts (league_id, kind, member_id, body)
values (p_league, 'system', my_member_id(p_league),
        case when p_finish = 'cup_final'
          then 'The Pro called it: the season ends in a Cup Final.'
          else 'The Pro called it: the points table crowns the champion.' end);
```

**Why** 82 chars of bylaw recital — three rule clauses after a colon, in caps, on a purely informational post. 'Final 4 weeks, scored fresh, top seeds only' is the rule, and the league's rules screen is where a rule can be read properly and re-read later; a feed row is a poor place to publish bylaws. 'SET THE FINISH:' is settings vocabulary; 'called it' is the same decision in the voice the app uses for the Pro. Natural case per the D66 precedent.

---

## push

This surface has almost no copy of its own: three of the five emit sites forward `record.body` verbatim from a database row, so the notification text IS the board-feed story, and every title is an unauthored label (league name, event name, or the literal 'Cup Season'). The fix is structural before it is editorial — posts need a short authored `push_title` (the result) and `push_body` (the context), a `first_name(text)` SQL helper, and a real deep link — after which the copy above fits a lock screen without any truncation at all. Char counts below are title + body of the delivered notification (excluding the `Title:` / `Body:` scaffolding); for generator items the title shown is what the forwarder supplies today.

### `index.ts`:227 — broken  (119 → 46 chars)

**Now**

```
Title: "PIGL"  Body: "Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units"
```

**Proposed**

```
Title: "Jerecho & Jade win 3&2"  Body: "PIGL · Sunningdale Rules"
```

**Source**

```js
  const first = (n?: string | null) => String(n ?? '').trim().split(' ')[0];
  const lgName = lg?.name ?? 'Cup Season';
  const isChat = record.kind === 'chat';
  await sendTo(recipients,
    isChat ? `${first(author?.display_name) || 'Someone'} · ${lgName}`
           : (record.push_title || lgName),
    isChat ? String(record.body ?? '')
           : (record.push_body  || lgName),
    `/?post=${record.id}`);
```

**Why** The highest-volume notification in the product has no copy at all — `lg?.name` is the title and `String(record.body ?? …)` is the body, so a feed story written for a screen that already shows the league, the avatar and the timestamp gets dumped onto a lock screen that shows none of them. The title is the only line read before a swipe and it is spent on 'PIGL', which the reader already knows. Fix: add `posts.push_title` (the result, authored by the generator) and `posts.push_body` (the context), and let the function pick them up. The league name moves into the body where it belongs as context, and the result takes the bold line. For kind='chat' there is no generator, so compose in the function: the chat insert at index.html:4950 writes `body: v` with no author, which is why chat currently pushes an anonymous sentence — take the speaker from the post's member_id and use `first(display_name)` for the title ('Jerecho · PIGL'), never the full display_name. Note the rendered example carries the new mode name: 'Sunningdale' alone read as the English course in a message whose footer said ARIZONA BILTMORE CC, so it is 'Sunningdale Rules' now. 'no handicaps' and 'bank: … 6 units' are engine words and are gone from the message entirely — the settlement card is the page, and the page is the proof.

### `20260716160000_ryder_slice3.sql`:183 — broken  (172 → 54 chars)

**Now**

```
Title: "Ryder Cup 2026"  Body: "SESSION 1: JERECHO FISCHBECK DEF. WILL PETERSON +2.4/+1.1 · ISAAK NGUYEN DEF. JADE ROBINSON +3.0/+0.2 · MIKE TORRES HALVED DAN REYES — TEAM ARIZONA LEAD 2½–1½"
```

**Proposed**

```
Title: "Arizona lead 2½–1½"  Body: "Session 1 settled — the duels are up"
```

**Source**

```js
  -- de-shout the scoreline it feeds (lines 179-181)
  v_score := case when pa = pb then 'All square ' || evhalf(pa) || '–' || evhalf(pb)
                  when pa > pb then v_na || ' lead ' || evhalf(pa) || '–' || evhalf(pb)
                  else v_nb || ' lead ' || evhalf(pb) || '–' || evhalf(pa) end;
  if v_lines is not null then
    perform event_post(v_event,
      v_score,                                                  -- push_title: the result, first
      'Session ' || v_no || ' settled — the duels are up',       -- push_body
      'Session ' || v_no || ': ' || v_lines || ' — ' || v_score); -- feed body, unchanged shape
  end if;
```

**Why** 158 chars of body for only three duels, and `|| ' — ' || v_score` appends the scoreline LAST — so `body.slice(0, 140)` at index.ts:35 amputates 'TEAM ARIZONA LEAD 2½–1½', the only part anyone cares about, and ends mid-word on 'TEAM ' with no ellipsis. It scales the wrong way: six duels runs past 280 chars, so the score is destroyed harder exactly as the event gets more important. The rewrite inverts the order — the scoreline becomes the push title, so it is the first thing delivered rather than the first thing cut — and the duel-by-duel table stops being pushed at all, because that is the page. '+2.4/+1.1' is raw PvI, the engine currency CLAUDE.md forbids on player-facing surfaces, and it is unlabeled besides. `upper(display_name)` is shouting and it is the full legal name six times; the newest generator at 20260726120000_match_story_override.sql:114 already carries the comment 'casing policy: de-shout a generator when already inside it' — this file was never converted. `v_score` at line 179-181 de-shouts in the same edit. The full duel list still goes to the feed as the third argument.

### `index.ts`:35 — broken  (140 → 36 chars)

**Now**

```
Body as delivered: "SESSION 1: JERECHO FISCHBECK DEF. WILL PETERSON +2.4/+1.1 · ISAAK NGUYEN DEF. JADE ROBINSON +3.0/+0.2 · MIKE TORRES HALVED DAN REYES — TEAM "
```

**Proposed**

```
Body as delivered: "Session 1 settled — the duels are up"
```

**Source**

```js
const clamp = (s: string, n = 80) => {
  const t = String(s ?? '').trim();
  if (t.length <= n) return t;
  const cut = t.lastIndexOf(' ', n - 1);
  return t.slice(0, cut > n * 0.6 ? cut : n - 1).replace(/[ ·—,]+$/, '') + '…';
};
// …inside sendTo(profileIds, title, body, url = '/'):
  const payload = JSON.stringify({ title: clamp(title, 48), body: clamp(body), url });
```

**Why** 140 is the wrong number in the wrong place. Lock screens render roughly 80–110 chars over two lines, so a body budgeted to 140 is elided a second time by the OS; and because every SQL generator concatenates left to right with the summary LAST, a hard cut systematically deletes the result and keeps the preamble — the exact inversion of result-first. It is also a double truncation: `event_post()` already caps at 400 (ryder_slice3.sql:47), game stories at 200 (20260726120000:113,132), announcements at 280 (20260712070000:23), each clipped again here, so no layer owns the final length. Truncation is the wrong repair anyway — it fixes the byte length of a badly shaped sentence instead of composing a short one. The rewrite keeps a clamp only as a guardrail, at a budget the screen actually shows, snapping to a word boundary with an ellipsis so a shortened line reads as a summary and not a transmission failure; and it takes a `url` argument so the notification finally deep-links. Today `url: '/'` is hardcoded on every notification and sw.js:77-84 focuses an existing window without navigating, so even the root path is discarded — which is precisely why the bodies grew long enough to need cutting: nothing else carried the detail. Hoist `clamp` to module scope so line 87 (APNs) shares it instead of holding a second copy of the magic number.

### `20260712090000_round_posts_traceable.sql`:22 — broken  (70 → 49 chars)

**Now**

```
Title: "PIGL"  Body: "JERECHO FISCHBECK POSTED 84 GROSS · PAPAGO GOLF COURSE · DIFF 11.4"
```

**Proposed**

```
Title: "Jerecho beat their number"  Body: "84 at Papago Golf Course"
```

**Source**

```js
  insert into posts (league_id, season_id, kind, round_id, member_id, push_title, push_body, body)
  select lm.league_id, s.id, 'round', new.id, lm.id,
         first_name(coalesce(p.display_name, 'A golfer')) || ' '
           || bandphrase((new.index_at_post * l.allowance / 100.0) - new.differential),
         new.gross || case when new.holes_played = 9 then ' for 9' else '' end
           || case when coalesce(new.course_label,'') <> ''
                   then ' at ' || new.course_label else '' end,
         first_name(coalesce(p.display_name, 'A golfer')) || ' '
           || bandphrase((new.index_at_post * l.allowance / 100.0) - new.differential)
           || ' · ' || new.gross
           || case when new.holes_played = 9 then ' for 9' else '' end
           || case when coalesce(new.course_label,'') <> ''
                   then ' at ' || new.course_label else '' end
  from league_members lm
  join profiles p on p.id = new.profile_id
  join leagues  l on l.id = lm.league_id
  join seasons  s on s.league_id = lm.league_id
                and s.status in ('active','cup_final')
                and new.played_on between s.starts_on and s.ends_on
  where lm.profile_id = new.profile_id;

-- companion helpers (same migration):
-- create or replace function public.first_name(n text) returns text
--   language sql immutable as $$ select nullif(split_part(trim(coalesce(n,'')), ' ', 1), '') $$;
-- create or replace function public.bandphrase(vs numeric) returns text
--   language sql immutable as $$ select case
--     when vs is null then 'posted a round'
--     when vs >= 3  then 'torched it'
--     when vs >= 1  then 'beat their number'
--     when vs >= -1 then 'played to their number'
--     when vs >= -3 then 'was a little loose'
--     else 'posted anyway' end $$;
```

**Why** 'DIFF 11.4' is pure engine vocabulary on a lock screen, and it is the last item so it reads as the punchline. CLAUDE.md is explicit that round cards speak the named bands and never differential — index.html:5114 `bandName()` is the app's own display language ('Torched it', 'Beat your number', 'Played to it') and index.html:5132 `theirs()` converts it to third person for surfaces showing someone else's round. This notification, the highest-volume one in the product, violates the app's established rule. There is also no result: 'POSTED 84 GROSS' says nothing about whether the round was good, which is the whole scoring premise. Verified this is the ONLY definition of `round_to_board()` in the repo, so the all-caps DIFF line is live in production today. The rewrite needs two new SQL helpers, both one-liners: `first_name(text)` returning `split_part(trim(n), ' ', 1)` — grep confirms zero uses of split_part on display_name anywhere in supabase/migrations/, while the client already does it ad hoc at index.html:8860 and index.html:13554, so the convention exists and has simply never reached the server where all push copy is minted — and `bandphrase(numeric)`, the SQL mirror of bandName()/theirs(). The band needs the league's allowance, so join `leagues l on l.id = lm.league_id`; a round with a null index_at_post falls back to 'posted a round'.

### `index.html`:7238 — broken  (156 → 42 chars)

**Now**

```
Title: "PIGL"  Body: "Sunningdale, everyone for themselves: Jerecho Fischbeck 5, Will Peterson 4, Isaak Nguyen 3, Jade Robinson 2 · no handicaps · bank: Jerecho Fischbeck 6 units"
```

**Proposed**

```
Title: "PIGL"  Body: "Jerecho takes the bank · Sunningdale Rules"
```

**Source**

```js
/* first token only — a text between friends never carries a legal name */
const fname = s => String(s||'Golfer').trim().split(' ')[0];

    story:`${m.bank.units===0
      ? 'Nobody took the bank'
      : `${fname(LIVE[m.bank.owner]?.n)} takes the bank${unit>0?`, $${m.bank.units*unit} each`:''}`} · Sunningdale Rules` };
```

**Why** 156 chars, so it cuts at 140 mid-name on the bank owner — 'bank: Jerecho F'. The bank line names who gets paid; that IS the settlement, and it is the exact text destroyed, for the same last-position reason as the Ryder session post. 'Sunningdale, everyone for themselves:' burns 37 chars — nearly half the visible budget — on a format name before a single player is named. 'no handicaps' is a rules-engine flag no one says in a group text; drop it (the card states the format). 'units' is internal accounting: with no stake set the message tells friends they won an abstract quantity, so with a stake say dollars and without one say nothing at all. `${line}` is built from `LIVE[i].n`, which is the full display_name (index.html:6738/6745/6859 all set `n:(…display_name||…)`) — four full legal names in one line. The per-player hole counts are the recap card's job, not the text's. Same edit applies to the team variant at index.html:7185-7186, which carries the same bare 'Sunningdale:' prefix and the same 'no handicaps · bank: …' tail; the mode is 'Sunningdale Rules' everywhere now, because the bare word read as the English course in a message whose footer said ARIZONA BILTMORE CC.

### `index.ts`:203 — broken  (127 → 49 chars)

**Now**

```
Title: "Ryder Cup 2026"  Body: "SESSION 1 PAIRINGS: JERECHO FISCHBECK VS WILL PETERSON · ISAAK NGUYEN VS JADE ROBINSON · MIKE TORRES VS DAN REYES"
```

**Proposed**

```
Title: "Session 2 is open"  Body: "Ryder Cup 2026 · your duel is up"
```

**Source**

```js
    const recipients = (eps ?? [])
      .filter((e) => e.profile_id !== record.author_profile_id)   // never ping the author
      .filter((e) => record.kind !== 'chat' || (e.notify_target ?? true))
      .map((e) => e.profile_id);
    console.log(`[push] kind=${record.kind} event=${record.event_id} recipients=${recipients.length}`);
    await sendTo(recipients,
      record.push_title || `${evt?.name ?? 'Your event'} update`,
      record.push_body  || `${evt?.name ?? 'Your event'} · tap for the scoreboard`,
      `/?event=${record.event_id}`);
```

**Why** The event branch mirrors the league branch's failure — it forwards `record.body` verbatim, so every event notification inherits the feed's shape and the feed's length — plus three faults the league branch does not have. It has no mute flag of any kind, so event players get every pairing, every session and every taunt with no opt-out. It has no author exclusion (the league branch filters `m.id !== record.member_id` at line 223), so an event post can buzz the person who caused it. And the title falls back to the hardcoded 'The Ryder' even for a Major or any other event type. The fallback body 'Something happened in your event' is a non-message — no actor, no result, no reason to open — and is handled at the twin site below. Rewrite: read `push_title` / `push_body` the same way as the league branch, honor `event_players.notify_target` for chat-grade kinds, exclude the author, and deep-link to the event so the message can stay a hook while the scoreboard carries the detail.

### `20260722211500_covenant_pulse_pairings.sql`:135 — broken  (127 → 46 chars)

**Now**

```
Title: "Ryder Cup 2026"  Body: "SESSION 1 PAIRINGS: JERECHO FISCHBECK VS WILL PETERSON · ISAAK NGUYEN VS JADE ROBINSON · MIKE TORRES VS DAN REYES"
```

**Proposed**

```
Title: "Session 1 is open"  Body: "3 duels are live — find yours"
```

**Source**

```js
  select string_agg(first_name(pa.display_name) || ' vs ' || first_name(pb.display_name), ' · ')
    into v_lines
    from event_duels d
    join event_players ea on ea.id = d.a_player join profiles pa on pa.id = ea.profile_id
    join event_players eb on eb.id = d.b_player join profiles pb on pb.id = eb.profile_id
   where d.session_id = p_session;
  perform event_post(v_event,
    'Session ' || v_no || ' is open',                                     -- push_title
    case when v_pairs = 1 then 'One duel is live — it''s yours'
         else v_pairs || ' duels are live — find yours' end,              -- push_body
    'Session ' || v_no || ' pairings: ' || v_lines);                      -- feed body
```

**Why** This broadcasts the entire pairing table to every player when each player cares about exactly one line — their own — so the one fact that matters ('you're on Will') is buried among everyone else's matchups. 113 chars at three duels, growing linearly: at five duels it crosses the 140 cut and the players at the end of the list never learn who they drew. Six full legal names, all shouted through `upper(pa.display_name)` — the same unfinished casing policy as the session-resolve post. 'SESSION 1 PAIRINGS:' leads with internal scheduling vocabulary. The honest fix inside the current one-post-fans-out architecture is to stop trying to be personal in a broadcast: the push says the session opened and how many duels there are, and the page shows you yours. The full table still ships as the feed body (third argument), now natural-case with `first_name()` and a lowercase ' vs '. If per-recipient pairing pushes are wanted later, the `push_nudges` table already does exactly that — one row per recipient — and is the right vehicle. Same edit applies to the older copy of this line at 20260716160000_ryder_slice3.sql:95.

### `20260716160000_ryder_slice3.sql`:241 — broken  (94 → 57 chars)

**Now**

```
Title: "Ryder Cup 2026"  Body: "RYDER CUP 2026: TEAM ARIZONA TAKE THE CUP 7½–4½ · MVP: JERECHO FISCHBECK (3-0-1)"
```

**Proposed**

```
Title: "Arizona take the cup 7½–4½"  Body: "Ryder Cup 2026 · Jerecho is MVP"
```

**Source**

```js
    perform event_post(v_event,
      case when v_win is null then 'The cup is shared ' || evhalf(pa) || '–' || evhalf(pb)
           when v_win = v_ta  then v_na || ' take the cup ' || evhalf(pa) || '–' || evhalf(pb)
           else                    v_nb || ' take the cup ' || evhalf(pb) || '–' || evhalf(pa)
      end,                                                                   -- push_title
      v_ename || coalesce(' · ' || first_name(mvp_name) || ' is MVP', ''),    -- push_body
      v_ename || ' · '
      || case when v_win is null then 'the cup is shared — ' || v_na || ' and ' || v_nb
              when v_win = v_ta  then v_na || ' take the cup ' || evhalf(pa) || '–' || evhalf(pb)
              else                    v_nb || ' take the cup ' || evhalf(pb) || '–' || evhalf(pa) end
      || coalesce(' · MVP: ' || mvp_name || ' (' || mvp_rec || ')', ''));     -- feed body
```

**Why** The event name is duplicated: it is already the notification title via `evt?.name` at index.ts:203, and `upper(v_ename) || ': '` repeats it as the first 16 chars of the body — a quarter of the visible line saying the same thing twice. The rewrite keeps the event name exactly once, in the body where it belongs as context, and gives the bold line to the result. This is the season's biggest moment and it currently arrives in the same flat all-caps register as a pairings list; natural case plus a result-led title is what makes it read differently. '(3-0-1)' is an unlabeled W-L-H record a casual reader will not decode on a lock screen — 'is MVP' is the reward, and the record belongs on the trophy card. MVP survives truncation now instead of being the sacrificial tail. Requires selecting `s.w` and `s.h` alongside `mvp_name` at line 225 rather than pre-joining them into `mvp_rec`, and `first_name()` on the MVP.

### `index.ts`:170 — broken  (63 → 39 chars)

**Now**

```
Title: "Cup Season"  Body: "Jerecho Fischbeck (@jerecho) wants to be golf buddies"
```

**Proposed**

```
Title: "Jerecho wants in your crew"  Body: "Tap to accept"
```

**Source**

```js
      await sendTo([record.addressee],
        `${first(p?.display_name) || 'Someone'} wants in your crew`,
        'Tap to accept',
        '/?crew=1');
```

**Why** The title is the literal app name, which the OS already renders above every notification with the icon — the bold line is a verbatim duplicate carrying zero information, so the whole message is squeezed into the body. '(@jerecho)' is database plumbing shown to a human: a handle in parentheses is a disambiguator for a search result, not something a person says. The fallback is visibly broken — with a null handle it renders 'A golfer (@?) wants to be golf buddies', a bare question mark as an identity. And 'golf buddies' is the app's only word for the relationship while the established vocabulary is 'crew' (CLAUDE.md voice: the Pro, crew, squad, the season); it appears here, again in the accept push, and again in the email body, so fixing it once here means fixing all three consistently. First name only, from the same `who()` lookup that already selects display_name.

### `index.ts`:228 — broken  (34 → 0 chars)

**Now**

```
Title: "PIGL"  Body: "Something happened on the board"
```

**Proposed**

```
(nothing is sent — the function logs `[push] skipped empty body kind=round post=<id>` and returns {"ok":false,"reason":"empty-body"})
```

**Source**

```js
  const line = String(record.push_body ?? record.body ?? '').trim();
  if (!line) {
    console.log(`[push] skipped empty body kind=${record.kind} post=${record.id} league=${record.league_id}`);
    return json({ ok: false, reason: 'empty-body', kind: record.kind });
  }
  await sendTo(recipients, record.push_title || lgName, line, `/?post=${record.id}`);
```

**Why** A notification that says nothing. No actor, no result, no reason to open — it fails every clause of the standard at once, and 'the board' is internal IA vocabulary for the posts table (players see a feed). There is no wording that rescues this, because the failure is that the post had nothing to say: the right rewrite is to not send. Any post worth buzzing a phone about has a generator that authored a line; a post with a null body is a bug upstream, and firing a content-free notification hides it. Today it is indistinguishable from a delivered notification in the logs, because line 226 logs only kind and recipient count. Its twin at index.ts:204, 'Something happened in your event', has the identical failure and takes the identical fix.

### `index.ts`:159 — broken  (2 → 32 chars)

**Now**

```
(nothing is emitted — the caller receives HTTP 200 with body "ok", identical to a successful delivery)
```

**Proposed**

```
(nothing is emitted — the caller receives HTTP 400 with body {"ok":false,"reason":"no-record"} and the log line `[push] no-op: payload had no record`)
```

**Source**

```js
const json = (o: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { 'content-type': 'application/json' } });

  if (!record) {
    console.log('[push] no-op: payload had no record');
    return json({ ok: false, reason: 'no-record' }, 400);
  }
// …and at each remaining exit, an outcome instead of 'ok':
//  184: return json({ ok: false, reason: 'friendship-ignored', type, status: record.status });
//  196: return json({ ok: false, reason: 'post-has-no-target', post: record.id });
//  191 / 205 / 230: return json({ ok: true, kind: record.kind, recipients: recipients.length });
//   28: if (!profileIds.length) { console.log('[push] no-op: empty recipient list'); return; }
```

**Why** Confirmed at exactly six sites — lines 159, 184, 191, 196, 205, 230 all return a bare 'ok'. Three of them can emit NOTHING while reporting HTTP 200: 159 (malformed payload), 184 (the shared exit for the whole friendships branch, so an INSERT with status != 'pending', a DELETE, or any UPDATE that is not pending→accepted all fall through having sent nothing), and 196 (a post with neither league_id nor event_id). None of those three log anything — the branch console.logs sit at 169/180/189/202/226 — so a dropped notification leaves no trace. A fourth silent no-op hides in `sendTo()` at line 28, which returns on an empty recipient list before its own logging. This is the identical signature to the season_email misroute documented in CLAUDE.md: pg_net logs 200 with body 'ok', the dashboard shows a healthy webhook, zero notifications are sent. CLAUDE.md's own remedy — 'never return a bare ok, and log every invocation, so a misroute is distinguishable from a no-op' — has not been applied to the very function whose behavior taught the lesson. Apply the shape below to all six sites, with an outcome-bearing reason on each and a log line on every silent exit including sendTo's.

### `index.ts`:87 — broken  (70 → 53 chars)

**Now**

```
Title: "PIGL"  Body: "JERECHO FISCHBECK POSTED 84 GROSS · PAPAGO GOLF COURSE · DIFF 11.4"
```

**Proposed**

```
Title: "Jerecho beat their number"  Subtitle: "PIGL"  Body: "84 at Papago Golf Course"
```

**Source**

```js
async function sendApns(profileIds: string[], title: string, body: string, subtitle = '', loud = false) {
  // …
  const payload = JSON.stringify({ aps: {
    alert: { title: clamp(title, 48), subtitle: clamp(subtitle, 32) || undefined, body: clamp(body) },
    ...(loud ? { sound: 'default' } : {}),
  } });
```

**Why** The 140-char slice is duplicated here rather than shared with the web-push builder at line 35, so one fix to the copy budget lands in one and misses the other — and because `sendApns()` is called from inside `sendTo()` at line 54 with the ORIGINAL untruncated body, both paths independently re-truncate the same string, making the APNs body silently depend on a constant defined 52 lines away in a different function. Hoisting `clamp` to module scope removes the second copy. APNs also supports a `subtitle` field — exactly the affordance this surface needs, result on the title line and context on the subtitle — and it is unused; passing the league or event name there frees the body entirely for the detail. Finally, `sound: 'default'` fires on every notification with no distinction between 'the cup was decided' and 'someone posted a round'; gate the sound on result-bearing kinds so the buzz means something. Dormant until the APNS_* secrets are set, so this ships with zero live risk — but it ships wrong today if it is not fixed before the Mac phase.

### `index.ts`:190 — confusing  (67 → 60 chars)

**Now**

```
Title: "Ryder Cup 2026"  Body: "Jerecho Fischbeck posted — +2.4 to beat · 3 days left"
```

**Proposed**

```
Title: "Jerecho beat their number by 2.4"  Body: "Ryder Cup 2026 · 3 days left"
```

**Source**

```js
  // forwarder (index.ts:188-192)
  if (table === 'push_nudges') {
    const line = String(record.body ?? '').trim();
    if (!line) { console.log(`[push] nudge skipped: empty body profile=${record.profile_id}`); return json({ ok: false, reason: 'empty-nudge' }); }
    console.log('[push] kind=nudge');
    await sendTo([record.profile_id], String(record.title ?? 'Your duel'), line,
      record.event_id ? `/?event=${record.event_id}` : '/');
    return json({ ok: true, kind: 'nudge', recipients: 1 });
  }

  -- generator (20260716160000_ryder_slice3.sql:414-419)
  --   insert into push_nudges (profile_id, title, body)
  --   values (d.opp_profile,
  --     coalesce(first_name(v_name), 'Your opponent') || ' beat their number by ' || round(v_best,1),
  --     d.ename || ' · '
  --     || case when d.days_left <= 0 then 'closes tonight'
  --             else d.days_left || ' day' || case when d.days_left = 1 then '' else 's' end || ' left' end);
```

**Why** This is the best notification on the surface and the model for the rest — one clause, genuinely personalized (one row per recipient, not a broadcast), already result-first. Its faults are narrow. 'Jerecho Fischbeck posted' should be 'Jerecho'. '+2.4 to beat' is an unlabeled engine number: it is the allowance-adjusted PvI from ryder_slice3.sql:406, and no player-facing glossary explains what beating +2.4 requires — the app's own phrase for that quantity is `vsPhrase()` at index.html:5124, 'beat your number by 2.4', in third person 'beat their number by 2.4'. That is longer but it is comprehensible, and it moves to the title so it is the line that survives. Two defects in the forwarder itself: `String(record.body ?? '')` coerces a null body to the empty string and sends it anyway — the only path in the function that can deliver a blank notification — and `record.title` is unvalidated and unbounded (`push_nudges.title` is 'text not null' with no length cap, ryder_slice3.sql:286) while only body is ever clamped, so a long event name overflows the title line. Both fixed by the clamp from index.ts:35 plus an explicit empty-body guard. At 60 chars this is at the ceiling, but the title alone is 32 and is the line actually read.

### `index.ts`:181 — wordy  (54 → 47 chars)

**Now**

```
Title: "Cup Season"  Body: "Jade Robinson accepted — you're golf buddies"
```

**Proposed**

```
Title: "Jade is in your crew"  Body: "You'll see their rounds now"
```

**Source**

```js
      await sendTo([record.requester],
        `${first(p?.display_name) || 'Your buddy'} is in your crew`,
        "You'll see their rounds now",
        '/?crew=1');
```

**Why** 'accepted' and "you're golf buddies" say the same thing twice in a 44-char line — half the budget is repetition — while the title burns its ten characters on the app name the OS already shows. The fallback is circular nonsense when the profile lookup fails: 'Your buddy accepted — you're golf buddies'. Full legal name. And it announces a state change with nothing to do about it — no reason to open, and `url` is '/' anyway. The rewrite puts the outcome in the title, replaces the redundant clause with the actual consequence (their rounds now appear in your feed, which is the thing the reader gains), keeps 'crew' consistent with the request push and the email, and deep-links to the crew view. 'their' rather than a gendered pronoun, matching the deliberate they/them rule at index.html:5131.

### `index.ts`:175 — wordy  (41 → 26 chars)

**Now**

```
Subject: "Jerecho Fischbeck added you on Cup Season"
```

**Proposed**

```
Subject: "Jerecho wants in your crew"
```

**Source**

```js
        `${first(p?.display_name) || 'Someone'} wants in your crew`,
```

**Why** Full legal name in a subject line, where inbox previews truncate hardest. 'on Cup Season' is redundant with the sender, which is already 'Cup Season' (index.ts:122). And the subject and the push body describe one action in two different tenses and two different verbs — the push says 'wants to be golf buddies', the email says 'added you' — so a person receiving both gets two inconsistent accounts of the same event. Matching the push title exactly fixes the inconsistency and the length in one edit, and puts 'crew' in the app's own vocabulary.

### `index.ts`:144 — wordy  (139 → 82 chars)

**Now**

```
"Jerecho Fischbeck (@jerecho) added you as a golf buddy on Cup Season. Open the app to accept and you'll see each other's rounds and scores."
```

**Proposed**

```
"Jerecho wants in your crew. Accept and their rounds land in your feed, all season."
```

**Source**

```js
  const who = first(fromName) || 'A golfer';
    <p style="font-size:16px;line-height:1.5"><strong>${who}</strong> wants in your crew.</p>
    <p style="font-size:16px;line-height:1.5">Accept and their rounds land in your feed, all season.</p>
    <p style="font-size:12px;color:#8c9992;line-height:1.5">Someone added you on Cup Season. <a href="${unsubUrl}" style="color:#8c9992">Unsubscribe</a>.</p>
```

**Why** `${who}` is built at line 141 as `${fromName} (@${fromHandle})` — full legal name plus handle in parentheses, the same plumbing leak as the push; drop the handle and take the first token. "you'll see each other's rounds and scores" is a features list describing what the database will do rather than what the person gets; 'their rounds land in your feed, all season' is the same fact stated as a consequence. 'on Cup Season' goes for the same reason as the subject — the sender already says it. Separately, the footer at line 149 reads 'Manage notifications in your Tour Card' and the email carries no unsubscribe link at all, unlike the D68 `email_unsubscribe` path built for season emails — the only opt-out currently requires opening the app and finding a settings screen. Mint an unsubscribe token the same way D68 does and put it in the footer; that is a plumbing change, so the `${unsubUrl}` placeholder below marks where it lands.

---

## outbound email copy

Three emails, two functions, and not one of them leads with a result a person could read in two seconds — every name is a full legal name, every CTA is a dead app root in a retired palette color, and the two most important lines in the whole surface ("Nobody won, and every buy-in comes back", "Your posted rounds stay on your card") are buried at the bottom in the smallest, dimmest text. Four of the twenty-three rewrites depend on data the payload already computes and throws away (`v_solo`, `st.finish`, `starts_on`/`ends_on`, `season_payouts.reason`), so the copy fix and the migration fix are the same commit; the bare "Sunningdale" rename does not touch this surface at all (no email string carries a game-mode name — it lives only on the share/board path at index.html:7185-7186, 7238).

### `index.ts`:203 — broken  (38 → 34 chars)

**Now**

```
Jerecho Fischbeck takes the Cup — PIGL
```

**Proposed**

```
Jerecho takes the Cup by 24 — PIGL
```

**Source**

```js
// hoisted above the send loop; `first` is the shared shortener (see line 39)
const first = (s: unknown) => String(s ?? '').trim().split(/\s+/)[0] || '';
const margin = p.champion_score != null && p.runnerup_score != null
  ? Math.round((p.champion_score - p.runnerup_score) * 10) / 10 : null;
const champShort = p.solo ? first(p.champion) : p.champion;   // squad names are NEVER shortened
const verb = p.solo ? 'takes' : 'take';
const cup  = p.cup ? 'the Cup Final' : 'the Cup';
const subject = `${champShort} ${verb} ${cup}${margin && margin > 0 ? ` by ${num(margin)}` : ''} — ${p.league}`;
```

**Why** Three defects in one line. (1) Full legal name: p.champion is profiles.display_name for a solo league (20260725180000_email_audit_fixes.sql:57-58) — take the first whitespace token, matching the two ad-hoc splits the client already does at index.html:8860 and 13554. The shortener must be gated on solo, because for a squad league p.champion is squads.name ('Bogey Boys') and 'Bogey' is not a squad. (2) Grammar: 'takes' here vs 'take' in the body at :92, one send with two conjugations, and 'Bogey Boys takes' is wrong. Both are fixed by the same flag. (3) The margin — the one number that answers 'by how much' — is already in the payload as champion_score/runnerup_score and never reaches the subject. REQUIRES season_email_payload to return two fields it already computes and discards: `'solo', v_solo` (20260725180000:47) and `'cup', (coalesce(st.finish,'cup_final') = 'cup_final' and exists(select 1 from cup_finalists where season_id = p_season))` — the same test crown_season uses at 20260724230000:41, which narrates 'take the Cup Final' while this email says 'the Cup'. Add both to the Payload type at :30-37. Skew-safe: `p.solo` undefined on an old payload falls through to the plural/full-name path, i.e. today's behavior.

### `index.ts`:91 — broken  (37 → 28 chars)

**Now**

```
Jerecho Fischbeck
take the Cup — PIGL
```

**Proposed**

```
Jerecho
takes the Cup — PIGL
```

**Source**

```js
<div style="font:400 38px Georgia,serif;line-height:1.05;color:#D8B25A;margin:10px 0 4px">${esc(champShort)}</div>
<div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86;margin-bottom:12px">${verb} ${cup} &mdash; ${esc(p.league)}</div>
```

**Why** Same two variables as the subject, so the headline and the subject can never disagree again. For the pilot's own structure — PIGL is solo — the live email currently reads 'Jerecho Fischbeck / take the Cup', which is ungrammatical at 38px. `champShort`, `verb` and `cup` must be computed in buildHtml (or passed in) since the subject computes them at :203; hoist the three consts to module scope beside `first` and derive both call sites from them. Gold #D8B25A stays: D76 keeps gold as the earned face for recap/settlement (index.html:15202) — it is the CTA that has to move to ember, not the champion's name.

### `index.ts`:56 — broken  (13 → 42 chars)

**Now**

```
412–388
BY 24
```

**Proposed**

```
CUP FINAL
412–388 points
24 clear of Isaak
```

**Source**

```js
const runnerShort = p.solo ? first(p.runner_up) : (p.runner_up ?? '');
const scoreLine =
  p.champion_score != null && p.runnerup_score != null
    ? `<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.14em;text-transform:uppercase;color:#98A29A">${p.cup ? 'Cup Final' : 'Season points'}</div>
       <div style="font:600 22px ui-monospace,Menlo,monospace;color:#ECEEF2;letter-spacing:.02em">
         ${esc(num(p.champion_score))}&ndash;${esc(num(p.runnerup_score))} points
       </div>
       <div style="font:13px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86;margin-top:4px">
         ${margin && margin > 0 ? `${esc(num(margin))} clear of ${esc(runnerShort)}` : `level with ${esc(runnerShort)}`}
       </div>`
    : (runnerShort ? `<div style="font:13px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86">over ${esc(runnerShort)}</div>` : '');
```

**Why** Four fixes. (1) '412–388' and 'BY 24' never say what they count — 'points' appears once, in the label. (2) The 'CUP FINAL' / 'SEASON POINTS' eyebrow resolves the scale collision the inventory found: in a cup_final league this pair is the four-week final while the 'Final table' three elements lower is season-long v_squad_standings, so the headline can read 412–388 over a table whose #1 row reads 96. Needs the same `p.cup` field as the subject. (3) 'by 24' becomes '24 clear of Isaak' — the margin now names who it is over, which is the actual answer to 'who won and by how much', and the runner-up is already in the payload and currently only shown in a label row at :95. (4) The whole block no longer vanishes when either score is null: it degrades to 'over Isaak' rather than shipping a champion with no result at all. Longer than the before because the before was unreadable; this is body copy, not a text. Kills 'level — the ladder decided it' entirely — see the tiebreak line.

### `index.ts`:65 — broken  (29 → 52 chars)

**Now**

```
DECIDED ON FEWEST ROUNDS USED
```

**Proposed**

```
Level on points — Jerecho got there in fewer rounds.
```

**Source**

```js
// the stored rungs are engine words; map them at the edge, never in the DB
// (20260724230000_season_result_columns.sql:142-145 sets these four values)
const TIE: Record<string, string> = {
  'months won':         'won more months',
  'best single month':  'had the bigger month',
  'fewest rounds used': 'got there in fewer rounds',
  'coin flip':          'won the coin flip',
};
const tie = p.tiebreak
  ? `<div style="font:13px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.72;margin-top:8px">Level on points &mdash; ${esc(champShort)} ${TIE[p.tiebreak] ?? 'took the tiebreak'}.</div>`
  : '';
```

**Why** 'fewest rounds used' is month_rank counting-cap machinery printed verbatim, and all-caps monospace makes it read like a log line. Each rung becomes a clause with a subject and a direction, which the current copy never states — 'decided on fewest rounds used' never says the champion used fewer. Map at the Edge Function, not in SQL: the stored values feed §14.3's ladder and crown_season's board post and must not change. The `?? 'took the tiebreak'` fallback means a future fifth rung degrades to a true sentence instead of leaking a new engine word. Sentence case, not caps. This line also absorbs the 'level — the ladder decided it' string deleted from :62 — 'the ladder' is a spec-internal name with no user-facing existence anywhere in the app.

### `index.ts`:77 — broken  (41 → 38 chars)

**Now**

```
You're owed $180
SETTLE BETWEEN YOURSELVES
```

**Proposed**

```
Your cut of the pot: $180
Cup champion
```

**Source**

```js
const yours =
  r.cents > 0
    ? `<div style="margin:18px 0 0;padding:12px 14px;border-radius:12px;background:rgba(255,90,46,.14);border:1px solid #FF5A2E">
         <div style="font:600 15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">Your cut of the pot: ${esc(money(r.cents))}</div>
         <div style="font:13px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:3px">${esc(r.reason ?? 'Season payout')}</div>
       </div>`
    : '';
```

**Why** 'You're owed $180' with no source is the one thing a settlement line must not leave open. It cannot name a debtor honestly — season_payouts (20260725100000_career_record.sql:17-25) stores only season_id/profile_id/cents/reason, and the pot is collective, so there is no single person who owes it. 'Your cut of the pot' is the true answer and it is the app's own word (index.html:14852, 14862). The second line stops being a caps micro-label and starts being the reason, which the ledger already records as user-facing prose — 'Cup champion', 'Runner-up', 'Points king' (20260725190000_payout_penny_fixes.sql:99, 114, 127). REQUIRES season_email_payload to add `'reason'` to each recipient object (a max(sp.reason) alongside the existing sum(sp.cents) at 20260725180000:91-92) and `reason?: string` on the Recipient type at :29. 'Settle between yourselves' is not lost — the footer at :103 already carries the money-moves truth in a full sentence, which is where it belongs. Green #2FA46A → ember #FF5A2E per D76: index.html:15181 states the rule for exactly this kind of block.

### `index.ts`:101 — broken  (22 → 24 chars)

**Now**

```
Run it back — Season 2  →  https://cupseason.app/
```

**Proposed**

```
See the rounds behind it  →  https://cupseason.app/?share=8f2c1a34-…
```

**Source**

```js
<a href="${APP}/${p.share ? `?share=${encodeURIComponent(p.share)}` : ''}" style="display:block;margin-top:22px;padding:13px 18px;border-radius:11px;background:#FF5A2E;color:#1C1208;font:600 15px -apple-system,Segoe UI,sans-serif;text-align:center;text-decoration:none">See the rounds behind it</a>
```

**Why** 'Season 2' is hardcoded — a league finishing its third season is invited to Season 2 — and it presumes a next season the crew may not want. The replacement is the §16 promise instead of a guess about the future: no points figure without a path to the rounds that produced it, which is a real reason to tap and is the only thing the email cannot inline. The deep link is buildable today — shares.kind already accepts 'recap' with a season ref (20260722190000_public_shares.sql:25, 68-72) — but create_share() gates on auth.uid(), which a service_role Edge Function does not have, so season_email_payload must mint the row itself and return `'share', <token>`: insert into shares(kind, ref_id, created_by) values ('recap', p_season, <champion's profile_id>) on conflict do nothing, since shares.created_by is NOT NULL (line 27). The `p.share ? … : ''` guard keeps the bare root working on a skewed deploy. Ember per D76. Once the link carries the detail, the inlined five-row table at :99-100 can drop to the top three.

### `index.ts`:178 — broken  (32 → 33 chars)

**Now**

```
PIGL was cancelled — your buy-in
```

**Proposed**

```
PIGL is off — your $40 comes back
```

**Source**

```js
const ok = await sendEmail(r.email, r.name ?? null,
  (r.cents ?? 0) > 0 ? `${league} is off — your ${money(r.cents ?? 0)} comes back`
                     : `${league} is off`,
  buildCancelHtml(league, { name: r.name ?? null, cents: r.cents ?? 0 }));
```

**Why** 'your buy-in' is a bare noun with no verb — from the subject alone the recipient cannot tell whether their money is coming back or gone, which makes a refund notice read as a loss notice. The good news is already per-recipient in this exact loop (r.cents, line 175-178), so a per-recipient subject costs nothing and puts the result first. 'is off' instead of 'was cancelled': shorter, active, and it drops the passive that hides the actor without falsely naming one — request_league_cancel routes through the Pro when the league is free and through a crew vote when money is in (20260726100000_league_cancellation.sql:86+), so the subject genuinely cannot say who did it. The cents === 0 branch stays two words rather than promising a refund that isn't owed.

### `index.ts`:136 — broken  (63 → 61 chars)

**Now**

```
You're owed $40 back
YOUR BUY-IN · SETTLE UP BETWEEN YOURSELVES
```

**Proposed**

```
Your $40 buy-in comes back
Whoever collected it sends it back.
```

**Source**

```js
const owed = r.cents > 0
  ? `<div style="margin:14px 0 0;padding:12px 14px;border-radius:12px;background:rgba(255,90,46,.14);border:1px solid #FF5A2E">
       <div style="font:600 15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">Your ${esc(money(r.cents))} buy-in comes back</div>
       <div style="font:13px -apple-system,Segoe UI,sans-serif;color:#98A29A;margin-top:3px">Whoever collected it sends it back.</div>
     </div>`
  : '';
```

**Why** 'Your buy-in · settle up between yourselves' is the exact middot-glued run-on the owner rejected in the share text — two unrelated clauses welded with a separator, in all-caps. Split into a headline that states the outcome ('comes back', not the ambiguous 'owed … back') and one sentence that answers who owes it. 'Whoever collected it' is the honest answer: the snapshot at 20260726100000:58-72 records each member's own paid buy-in total and no counterparty, so no name exists to print, but the person who took the money is unambiguous to the crew. Green → ember per D76, same rule as the recap payout block.

### `index.ts`:148 — broken  (114 → 164 chars)

**Now**

```
Cup Season keeps the books — money moves friend-to-friend, never through us. Your posted rounds stay on your card.
```

**Proposed**

```
Your rounds stay on your card — all of them.
[Open your card]
Cup Season keeps the books — money moves friend-to-friend, never through us.
Turn off Cup Season emails
```

**Source**

```js
<div style="margin:18px 0 0;font:15px -apple-system,Segoe UI,sans-serif;color:#ECEEF2">Your rounds stay on your card &mdash; all of them.</div>
<a href="${APP}/" style="display:block;margin-top:16px;padding:13px 18px;border-radius:11px;background:#FF5A2E;color:#1C1208;font:600 15px -apple-system,Segoe UI,sans-serif;text-align:center;text-decoration:none">Open your card</a>
<div style="font:11px -apple-system,Segoe UI,sans-serif;color:#8A938A;margin-top:20px;line-height:1.5">
  Cup Season keeps the books &mdash; money moves friend-to-friend, never through us.<br>${unsub}
</div>
```

**Why** 'Your posted rounds stay on your card' is the reassurance that matters most to someone whose league just died, and it is currently the last clause of the smallest, dimmest text in the email. Promote it to a full-size line of its own and give it the CTA the email completely lacks — buildCancelHtml (:135-152) ships no button, no link, nothing. The league is deleted so there is nothing to deep-link to, but the card is exactly where the copy just sent them, so the app root is honest here. Longer than the before because the before was missing two required elements, not because the sentences grew. The unsubscribe is the serious gap: this mail reaches members who already turned season emails off, because cancel_league_now never joins email_prefs (20260726100000:58-72 filters placeholder addresses only). Add the token to the snapshot — the same insert-then-select backfill season_email_payload does at 20260725180000:52-54 — and pass it into buildCancelHtml. Since email_unsubscribe only flips `recap`, give it a defaulted second arg (`p_kind text default 'recap'`) so the new call is skew-safe against an un-pushed migration.

### `index.ts`:175 — broken  (41 → 32 chars)

**Now**

```
Jerecho Fischbeck added you on Cup Season
```

**Proposed**

```
Jerecho wants to be golf buddies
```

**Source**

```js
await sendEmail(
  a?.email ?? '', a?.display_name ?? '',
  `${first(p?.display_name) || 'A golfer'} wants to be golf buddies`,
  friendRequestEmail(a?.display_name ?? '', p?.display_name ?? 'A golfer', p?.handle ?? '', unsubUrl),
);
```

**Why** Full legal name, and 'added you on Cup Season' is LinkedIn phrasing that uses none of the app's own vocabulary. 'wants to be golf buddies' is not invented — it is the exact wording of the web push fired three lines above at :171, so the push and the email finally say the same thing, and 'wants' carries the pending state that 'added' hides. Needs the shared `first` helper in this file (push/index.ts has no shortener of any kind today); both display_names here are profiles rows fetched at :162-166, so the first whitespace token is the only available shortening and matches the client's own habit at index.html:8860, 13554. Under 60 chars with room to spare.

### `index.ts`:139 — broken  (21 → 8 chars)

**Now**

```
Hi Jerecho Fischbeck,
```

**Proposed**

```
Hi Jade,
```

**Source**

```js
const first = (s: unknown) => String(s ?? '').trim().split(/\s+/)[0] || '';
function friendRequestEmail(toName: string, fromName: string, fromHandle: string, unsubUrl: string) {
  const greeting = toName ? `Hi ${first(toName)},` : 'Hi,';
  const who = fromHandle ? `${first(fromName)} (@${fromHandle})` : (first(fromName) || 'A golfer');
```

**Why** A greeting is the single place where a first name is mandatory, and this is the one string in the product that gets it most wrong — 'Hi Jerecho Fischbeck,' is how a database addresses you, not how a friend does. Both values come from profiles.display_name (push/index.ts:164), so the fix is the first whitespace token in both directions. The handle stays on `who` but drops out of the greeting entirely: a handle is a disambiguator for a name you might not recognize, which is the sender's job, never the recipient's. Note there is no `esc()` in this file — unlike season-email/index.ts:39, display_name is interpolated raw into HTML here, so a name containing markup ships into the recipient's inbox unescaped; port the same esc helper over when touching these lines.

### `index.ts`:142 — broken  (177 → 114 chars)

**Now**

```
Hi Jerecho Fischbeck,
Jerecho Fischbeck (@jerecho) added you as a golf buddy on Cup Season.
Open the app to accept and you'll see each other's rounds and scores.
[Open Cup Season]
```

**Proposed**

```
Hi Jade,
Jerecho (@jerecho) wants to be golf buddies.
Accept and you'll see each other's rounds.
[Accept in the app]
```

**Source**

```js
const APP = Deno.env.get('APP_URL') ?? 'https://cupseason.app';
// ...
return `<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:480px;margin:0 auto;color:#1a2620">
  <p style="font-size:16px;line-height:1.5">${greeting}</p>
  <p style="font-size:16px;line-height:1.5"><strong>${esc(who)}</strong> wants to be golf buddies.</p>
  <p style="font-size:16px;line-height:1.5">Accept and you&rsquo;ll see each other&rsquo;s rounds.</p>
  <p style="margin:24px 0">
    <a href="${APP}/?buddy=1" style="background:#FF5A2E;color:#1C1208;text-decoration:none;font-weight:600;padding:12px 22px;border-radius:10px;display:inline-block">Accept in the app</a>
  </p>
```

**Why** Four fixes at once. (1) First names, and the same 'wants to be golf buddies' as the subject and the push. (2) 'and scores' is redundant with 'rounds' — a round is its score — so the sentence loses a third of its length and none of its meaning. (3) The hardcoded 'https://cupseason.app' becomes APP_URL, which season-email/index.ts:27 already honors; today the two functions cannot be pointed at a staging origin together. (4) Gold #E9BE62 is the pre-D76 palette and this is the third distinct CTA color across three emails — ember per index.html:15189. The `?buddy=1` param does not exist client-side yet, but unknown query params are ignored by boot (only ?unsub and ?share take over, index.html:15173, 15195), so the link degrades to Home exactly as today and the CTA text 'Accept in the app' stays true either way; wiring the param to open the pending-requests pane is the follow-up that makes standard 5 hold. This function's markup is also light-mode (#1a2620) while both season-email templates are hard-dark — no shared shell exists, so a brand pass currently has to be applied three times by hand.

### `index.ts`:149 — broken  (100 → 54 chars)

**Now**

```
You're getting this because someone added you on Cup Season. Manage notifications in your Tour Card.
```

**Proposed**

```
Jerecho added you on Cup Season. Turn off buddy emails
```

**Source**

```js
<p style="font-size:12px;color:#8c9992;line-height:1.5">${esc(first(fromName)) || 'Someone'} added you on Cup Season. ${unsubUrl ? `<a href="${unsubUrl}" style="color:#8c9992">Turn off buddy emails</a>` : ''}</p>
```

**Why** Two lies in one line. 'someone' is coy when the email just named the person in bold two paragraphs up, and 'Manage notifications in your Tour Card' points at a pane (index.html:11551-11557) where no switch governs this email — phMailTog covers the season recap only, so the instruction sends the recipient to a control that does not exist. This is also the highest-volume outbound mail in the product and the only one that can reach a person who has never opened the app, and it has the weakest consent affordance of the three: no token, no preference check, nothing. The D68 machinery already exists (email_prefs.token, email_unsubscribe) and is simply unwired here — add a `buddy` boolean to email_prefs, check it before the send at :173, and pass `${APP}/?unsub=<token>` in as unsubUrl. The `unsubUrl ? … : ''` guard means the copy degrades to a true statement rather than a dead link if the token lookup fails. Also fix the sandbox hole while in this function: sendEmail at :114 guards only @cupseason.invalid, so a sandbox profile's friend request still mails a @sandbox.cupseason.test address that both season-email paths correctly exclude (20260725180000:99-100, 20260726100000:70-71).

### `index.ts`:108 — broken  (38 → 96 chars)

**Now**

```
From: Cup Season <hello@cupseason.app>
```

**Proposed**

```
From: Cup Season <hello@cupseason.app>
Reply-To: Cup Season <hello@cupseason.app>
List-Unsubscribe: <https://cupseason.app/?unsub=8f2c1a34-…>
List-Unsubscribe-Post: List-Unsubscribe=One-Click

[plain text part]
Jerecho takes the Cup by 24 — PIGL.
Your cut of the pot: $180.
See the rounds behind it: https://cupseason.app/?share=…
```

**Source**

```js
async function sendEmail(to: string, name: string | null, subject: string, html: string, text: string, unsubUrl?: string) {
  // ...
      body: JSON.stringify({
        sender: { name: 'Cup Season', email: Deno.env.get('BREVO_SENDER') ?? 'hello@cupseason.app' },
        to: [{ email: to, name: name || undefined }],
        replyTo: { name: 'Cup Season', email: Deno.env.get('BREVO_REPLY_TO') ?? 'hello@cupseason.app' },
        subject,
        htmlContent: html,
        textContent: text,
        headers: unsubUrl ? {
          'List-Unsubscribe': `<${unsubUrl}>`,
          'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click',
        } : undefined,
      }),
```

**Why** The sender line itself is correct — this is about the three things missing beside it. (1) No textContent: every send is HTML-only, so Brevo derives the plain-text part itself and the derived preview becomes the raw eyebrow, which is precisely the weak preview line fixed at :90. A hand-written text twin is four lines and states the result, the money, and the link — a plain-text reader gets the same three facts, in the same order. (2) No List-Unsubscribe / List-Unsubscribe-Post, so Gmail's and Apple Mail's native one-click control never appears on the one email that has a perfectly good token; adding it is the difference between an opt-out and a findable opt-out, and it materially protects the sending domain. (3) No replyTo — a reply to a season recap goes to hello@cupseason.app with nothing routing it; set it explicitly and behind an env var so it can be pointed at a real inbox without a redeploy. The same three gaps exist verbatim in push/index.ts:111-127.

### `index.ts`:90 — confusing  (15 → 39 chars)

**Now**

```
SEASON COMPLETE
```

**Proposed**

```
You're owed $180 — the table is inside.
```

**Source**

```js
// hidden preheader — this is what the phone shows under the subject
const preheader = r.cents > 0
  ? `You&rsquo;re owed ${esc(money(r.cents))} &mdash; the table is inside.`
  : `${esc(runnerShort)} second &mdash; the table is inside.`;
// the eyebrow stops doing preview duty and starts carrying the season's span
const MON = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const day = (iso: string) => { const [ , m, d ] = String(iso || '').split('-').map(Number); return m ? `${MON[m-1]} ${d}` : ''; };
const span = p.starts_on && p.ends_on ? `${day(p.starts_on)} &ndash; ${day(p.ends_on)}` : 'Season complete';
// ...in the body:
<div style="display:none;max-height:0;overflow:hidden;opacity:0">${preheader}</div>
<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A">${span}</div>
```

**Why** The two lines a phone shows in the list view are currently 'Jerecho Fischbeck takes the Cup — PIGL' / 'SEASON COMPLETE' — the second says nothing the first didn't. A hidden preheader takes over preview duty and carries the one fact the subject can't: the recipient's own money, which is already per-recipient in r.cents. It never duplicates the subject, so standard 5 holds inside the inbox itself. The freed eyebrow takes the season span from starts_on/ends_on — two payload fields (20260725180000:110-111) that buildHtml never reads. Parse them by hand into y/m/d; never `new Date('YYYY-MM-DD')`, which lands on the previous day in Phoenix. Over 60 chars is fine here: this is a preview line, not a text message, and Gmail truncates around 90.

### `index.ts`:144 — confusing  (110 → 84 chars)

**Now**

```
LEAGUE CANCELLED
PIGL has been called off
The season won't be played. Nobody won, and every buy-in comes back.
```

**Proposed**

```
PIGL
Called off
The season won't be played. Nobody won, and every buy-in comes back.
```

**Source**

```js
<div style="font:11px ui-monospace,Menlo,monospace;letter-spacing:.16em;text-transform:uppercase;color:#98A29A">${esc(league)}</div>
<div style="font:400 30px Georgia,serif;line-height:1.1;color:#ECEEF2;margin:10px 0 6px">Called off</div>
<div style="font:14px -apple-system,Segoe UI,sans-serif;color:#ECEEF2;opacity:.86">The season won&rsquo;t be played. Nobody won, and every buy-in comes back.</div>
```

**Why** 'LEAGUE CANCELLED' and 'PIGL has been called off' say the same thing twice in two registers, and the eyebrow is what the inbox previews — so the preview line is again pure duplication of the subject. Swapping the eyebrow to the league name makes it carry identity instead of repeating status, and the headline shortens to the two words that matter. 'The season won't be played. Nobody won, and every buy-in comes back.' is the best sentence in the whole email surface and is kept verbatim; it also now feeds the subject (see :178), which is where it always belonged. Straight apostrophe → &rsquo; to match the recap's :80, so one file stops shipping two typographic conventions.

### `index.html`:15185 — confusing  (116 → 123 chars)

**Now**

```
You're unsubscribed
No more season-end emails. Your league and your rounds are untouched — this only stops the mail.
```

**Proposed**

```
Season emails are off
That's the only thing this changes. Your league, your rounds, and your card stay exactly as they are.
```

**Source**

```js
<div style="font-family:Georgia,serif;font-size:26px;margin:16px 0 8px">${ok?'Season emails are off':'That link isn&rsquo;t valid'}</div>
      <p style="color:#8E979E;font-size:13px;line-height:1.6;margin:0 0 20px">${ok
        ? 'That&rsquo;s the only thing this changes. Your league, your rounds, and your card stay exactly as they are.'
        : 'Nothing changed. You can turn season emails off any time from your Tour Card.'}</p>
```

**Why** The copy quality is genuinely high — it is the truth conditions that are off. 'That link has expired' is the wrong failure mode: email_unsubscribe takes an unguessable token that never expires (20260725140000_season_email.sql:143-151), so the only way to reach that branch is a string that isn't a parseable uuid, which is 'not valid', not 'expired'. The success branch also can't claim a row changed — the RPC is deliberately non-probeable and always returns true, so `ok = !error` is true whether or not anything was updated. Rewriting the headline as a state ('Season emails are off') rather than an event ('You're unsubscribed') makes it true in both cases: for the real token it just happened, and for a tampered one the statement still describes the account the token would belong to. The body gains 'your card' because that is the object a person actually worries about losing, and points the failure branch at the Tour Card switch, which is the one verifiable path. Slightly longer than the before, and worth it — this is a full-screen takeover, not a message.

### `index.html`:11556 — confusing  (16 → 22 chars)

**Now**

```
Season email: ON
```

**Proposed**

```
Season recap email: On
```

**Source**

```js
<button class="mini" id="phMailTog">Season recap email: —</button>
/* and the paint call at index.html:11815 */
const paint = on => { mailBtn.textContent = 'Season recap email: ' + (on ? 'On' : 'Off'); mailBtn.dataset.on = on ? '1' : ''; };
```

**Why** 'Season email' reads as if it governs all Cup Season mail, and it governs exactly one send — the recap when the season closes. It does not touch the friend-request email (push/index.ts:173 ignores email_prefs entirely) or the cancellation email (20260726100000:58-72 never joins it), so a user who turns this off and then receives either one has been told something false by the label. 'recap' is the word that scopes it, and it matches the kind stored in email_queue ('season_recap', 20260725140000:28). ON/OFF → On/Off: all-caps inside a sentence-case label is the only thing distinguishing this row from its three push neighbors, and it distinguishes them on the wrong axis — the word 'email' is what separates mail from pings.

### `index.html`:11558 — confusing  (104 → 160 chars)

**Now**

```
Moments, reveals, and month closes always come through. Round posts and chat each have their own switch.
```

**Proposed**

```
Pings: moments, reveals, and month closes always come through; round posts and chat have their own switch. Email: one recap when the season ends — nothing else.
```

**Source**

```js
<p class="fine" style="padding-left:0">Pings: moments, reveals, and month closes always come through; round posts and chat have their own switch. Email: one recap when the season ends &mdash; nothing else.</p>
```

**Why** This paragraph describes push only but now sits under a row that includes an email switch, so it reads as a promise that month closes 'always come through' by email too — they do not; no month-close email exists anywhere in the product. Labeling the two halves fixes the misattribution and gives the Season recap switch the explanation it currently has nowhere in the app: 'one recap when the season ends' is the frequency answer a button label has no room for. Over 60 chars deliberately — this is settings fine print, not a message in a thread, and the 60-char rule exists for strings read in a moving group chat. 'each have' → 'have' drops a word that was doing nothing.

### `index.html`:12941 — wordy  (80 → 40 chars)

**Now**

```
Sent to jerechofischbeck@gmail.com. Type the sign-in code from the newest email.
```

**Proposed**

```
Code sent to jerechofischbeck@gmail.com.
```

**Source**

```js
authStatus(`Code sent to ${email}.`,'ok');
```

**Why** On the first send there is only one email, so 'from the newest email' asks the user to solve a problem they don't have yet — and 'Type the sign-in code' narrates the input box they are already staring at, with the cursor in it. The newest-wins caveat is genuinely load-bearing but only after a resend, and it already lives on that exact path at index.html:12911 ('Fresh code sent to ${email} — the newest email wins.') and in the spam hint at :12900. Cutting it here removes the duplication and halves the line. Standing caveat this copy cannot resolve: this and :12900 are the only strings in the repo that describe the OTP email, and the template itself lives in the Supabase dashboard with nothing in git (no supabase/templates/, and config.toml:246-255 is commented scaffold), so every promise made about that email is unverifiable from source.

### `index.html`:12900 — wordy  (98 → 75 chars)

**Now**

```
No code yet? Check spam for the newest Cup Season email — older codes retire when a new one sends.
```

**Proposed**

```
No code yet? Check spam for a Cup Season email. Only the newest code works.
```

**Source**

```js
authStatus('No code yet? Check spam for a Cup Season email. Only the newest code works.');
```

**Why** 'older codes retire when a new one sends' is engine phrasing for token invalidation — 'retire' is a word about the system's state, and a person would say 'only the newest code works', which is the same fact from the reader's side and eight characters shorter. 'the newest Cup Season email' also asks the user to sort their spam folder by date before they can act; 'a Cup Season email' is what they actually search for, and the newest-code rule then stands on its own as a separate sentence. Both halves still depend on the dashboard template's From name being literally 'Cup Season' — not verifiable from this repo, and worth confirming in the Supabase dashboard before shipping copy that instructs a search on it.

### `index.ts`:84 — fine  (22 → 22 chars)

**Now**

```
Turn off season emails  →  https://cupseason.app/?unsub=8f2c1a34-…
```

**Proposed**

```
Turn off season emails  →  https://cupseason.app/?unsub=8f2c1a34-…
```

**Source**

```js
const unsub = r.token
  ? `<a href="${APP}/?unsub=${encodeURIComponent(r.token)}" style="color:#8A938A;text-decoration:underline">Turn off season emails</a>`
  : '';
```

**Why** The strongest string on the surface — four words, says exactly what happens, no hedging, no 'manage your preferences'. Copy unchanged. Two non-copy fixes ride along: #5E665E on #0A0E0C is roughly 3:1, a dimmed opt-out that reads as reluctance, so lift it to #8A938A (about 5:1) — and the same lift applies to the footer it shares a color with. The bigger gap is structural, covered at :108: with no List-Unsubscribe header, Gmail and Apple Mail never show their native one-click control, so this link is the only exit. The `r.token` null branch should be made unreachable rather than silently shipping an email with no opt-out at all — the backfill at 20260725180000:52-54 makes it unlikely, so log and skip the send if token is null instead of mailing anyway.

### `index.ts`:102 — fine  (76 → 76 chars)

**Now**

```
Cup Season keeps the books — money moves friend-to-friend, never through us.
```

**Proposed**

```
Cup Season keeps the books — money moves friend-to-friend, never through us.
```

**Source**

```js
<div style="font:11px -apple-system,Segoe UI,sans-serif;color:#8A938A;margin-top:20px;line-height:1.5">
  Cup Season keeps the books &mdash; money moves friend-to-friend, never through us.<br>${unsub}
</div>
```

**Why** Correct in voice and correct in substance (D39) — this is the sentence the whole positioning rests on and it should not be touched. The only change is the color lift from #5E665E to #8A938A so the honest line stops reading as legal boilerplate. Its placement is now defensible too: with the payout block above it saying 'Your cut of the pot', this footer is the sentence that explains how that cut actually moves.

---

## landing-and-og

Every outbound string on this surface is static, and that is the whole bug: the seven head tags cannot carry a result by construction, so the only per-share copy in the file (three good `document.title` lines) reaches nobody but a human already on the page. Below that, the settlement branch is the worst copy in the repo — a 115-char run-on headline with full legal names and engine words ("no handicaps", "bank: 6 units"), plus a money line that is factually wrong on the exact game the owner texted about. The fix is three shared primitives (a `fn()` first-name reducer, a `SUNNINGDALE RULES` label, and an `og` payload emitted at the edge), then most of these strings collapse to under 30 characters on their own.

### `index.html`:25 — broken  (56 → 35 chars)

**Now**

```
Cup Season — season-long fantasy golf with your own crew
```

**Proposed**

```
Jerecho & Jade win 3&2 · Cup Season
```

**Source**

```js
<title>${og.title ? og.title + ' · Cup Season' : 'Cup Season'}</title>
```

**Why** The tab is where the recipient confirms they opened the right thing; today it says the same category pitch for a settlement, a round, a recap and the marketing root. The per-share title code ALREADY EXISTS at index.html:15245 / 15284 / 15304 — it just runs after the crawler has left. Move that composition into the head via the edge function (see og:title, line 15) so one `og.title` feeds <title>, og:title and twitter:title, killing the current three-different-one-liners problem. Static fallback drops to the bare brand name: 'Cup Season' is a better tab label than 56 chars of tagline that truncates anyway. Note the mode name is gone from the title — the eyebrow on the card carries 'SUNNINGDALE RULES'; a title that leads with a mode name buries the result.

### `index.html`:15 — broken  (51 → 22 chars)

**Now**

```
Cup Season — season-long fantasy golf for your crew
```

**Proposed**

```
Jerecho & Jade win 3&2
```

**Source**

```js
<meta property="og:title" content="${og.title || 'Cup Season'}">
```

**Why** This is the bold line in the iMessage unfurl and it is the single reason the owner's link 'showed nothing'. No copy edit fixes it: the tag is a literal in <head>, nothing mutates og:* at runtime, and there is no edge function or prerender. Ship a Netlify Edge Function on `/` that, when `?share=TOKEN` is present, calls `share_info` and injects an `og` payload; then the composition is per-kind — settlement `${fnSide(winSide)} win ${status}` → 'Jerecho & Jade win 3&2'; round `${fn(info.name)} shot ${info.gross} at ${info.course}` → 'Jerecho shot 84 at Papago'; recap `${info.champion} take the ${info.league} cup`. `fnSide` is the new first-name reducer (`const fn = s => String(s||'').trim().split(/\s+/)[0]; const fnSide = s => String(s||'').split(' & ').map(fn).join(' & ');`) — required because share_info hands over `profiles.display_name` whole (migration 20260723230000, lines 48/63/107) and no first-name helper exists on any public path. Static fallback is the bare brand name; the tagline moves to og:description where the small grey line belongs.

### `index.html`:16 — broken  (161 → 49 chars)

**Now**

```
Rally your crew and post the real rounds you already play. Captains draft squads, points build for months, the endgame settles it — and the pot stays on the books.
```

**Proposed**

```
Sunningdale Rules at Arizona Biltmore CC · Jul 25
```

**Source**

```js
<meta property="og:description" content="${og.desc || 'Rally your crew. Post real rounds. Take the cup.'}">
```

**Why** 161 chars into a slot most clients truncate at 100–120, so it clips mid-clause on the exact channel it exists for. Under the edge-function fix this becomes the supporting line: og:title carries who won and by how much, og:description carries where and when. Note the naming decision applied — 'Sunningdale Rules', never bare 'Sunningdale', which read as the venue in a message whose footer said ARIZONA BILTMORE CC. 'Rules at <course>' also disambiguates by construction. Round kind renders 'Torched it — beat their number by 3.2'; recap renders 'Final standings · Jan 7 — Jun 28'. Static fallback is the door hero, matched to line 14 and manifest.webmanifest:4.

### `index.html`:17 — broken  (21 → 34 chars)

**Now**

```
https://cupseason.app
```

**Proposed**

```
https://cupseason.app/?share=8f2c1a
```

**Source**

```js
<meta property="og:url" content="${og.url || 'https://cupseason.app'}">
```

**Why** Not a copy problem — a cache-poisoning problem that presents as one. Every /?share= link declares itself canonical-equal to every other, so a chat client that dedupes by og:url reuses ONE preview for every settlement ever sent in that thread: the second card in a group thread renders the first one's. That is indistinguishable from 'the preview is broken' and would survive a perfect copy rewrite. The edge function must echo the actual request URL. Until it exists, deleting this tag is strictly better than shipping a wrong canonical — absent og:url makes clients key on the request URL, which is correct.

### `index.html`:19 — broken  (38 → 35 chars)

**Now**

```
https://cupseason.app/og-image.png?v=3
```

**Proposed**

```
https://cupseason.app/og/8f2c1a.png
```

**Source**

```js
<meta property="og:image" content="${og.image || 'https://cupseason.app/og-image.png?v=3'}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="${og.title || 'Cup Season'}">
```

**Why** This is the owner's 'generic static og-image with no result in it', and `twitter:card = summary_large_image` (line 22) renders it at MAXIMUM size — the preview is mostly a logo where the score should be. Confirmed single static file: stamp-version.sh copies og-image.png verbatim, and supabase/functions/ holds courses, push, scan, season-email, test-seed, weather — no image renderer. 'Less words and more visuals' is answered here or nowhere: a per-token 1200x630 card rendering 'JERECHO & JADE · 3&2' at display size is the visual, and it lets the message body shrink to a hook because the picture carries the detail (Rule 5). `og:image:alt` is added because the preview is currently silent to screen readers.

### `index.html`:15283 — broken  (7 → 17 chars)

**Now**

```
SETTLED
```

**Proposed**

```
SUNNINGDALE RULES
```

**Source**

```js
const GAME = { match:'MATCH PLAY', wolf:'WOLF', skins:'SKINS', sunningdale:'SUNNINGDALE RULES', none:'THE ROUND' };
    const eyebrow = r.mode === 'solo'
      ? (info.game === 'sunningdale' ? 'SUNNINGDALE RULES' : 'ROUND ROBIN')
      : (GAME[info.game] || 'THE ROUND');
    document.title = `${head} · Cup Season`;
```

**Why** Bug, not taste. supabase/migrations/20260725220000_sunningdale_game.sql:24 added 'sunningdale' to the live_rounds CHECK and index.html:2693 ships the picker, but this map never learned it — so the gold eyebrow falls back to 'SETTLED' (line 15295), an engine word, on the exact card the owner texted. The naming decision lands here: 'SUNNINGDALE RULES', never bare 'Sunningdale'. Two more fixes ride along: rrResult() (index.html:7221) returns `game:'match', mode:'solo'`, so a 4-man round robin currently unfurls as 'MATCH PLAY' — but `mode` is not in share_info's v_res, so add `'mode', lr.game_result->>'mode'` to the jsonb_build_object at 20260723230000_share_info_no_league.sql:57. And the tab title stops being noun-as-status ('Settlement at Papago') and reuses the card's own result headline. Also rename the picker button at index.html:2693 to 'Sunningdale Rules' so the label the player picks matches the label the card prints.

### `index.html`:15289 — broken  (20 → 21 chars)

**Now**

```
Bragging rights only
```

**Proposed**

```
Jerecho & Jade up $60
```

**Source**

```js
const unit = Number(r.unit ?? r.stake) || 0;
    const money = !unit ? 'Bragging rights only'
      : (r.transfers || []).length
          ? (r.transfers.length <= 2
              ? r.transfers.map(t => `${fn(t.from)} owes ${fn(t.to)} $${t.amt}`).join(' · ')
              : `$${r.transfers.reduce((s,t) => s + Number(t.amt), 0)} changes hands`)
      : Number(r.bank_units) ? `${fnSide(r.bank_side)} up $${Number(r.bank_units) * unit}`
      : `$${unit} a side`;
```

**Why** FACTUALLY WRONG today, and on the one format whose whole point is the money layer. sunnResult() (index.html:7187) and sunnSoloResult() (7235) emit `unit`, never `stake`, and never `transfers`; share_info reads only `game_result->>'stake'` (20260723230000:60) and jsonb_strip_nulls drops it — so `Number(r.stake) > 0` is false on every Sunningdale card and a $60 bank publicly renders as 'Bragging rights only'. Requires two source changes: sunnResult must also return `bank_side: names(m.bank>0?0:1)` and `bank_units: Math.abs(m.bank)` (sunnSoloResult the same from `m.bank.owner`/`m.bank.units`), and share_info must pass `unit`, `bank_side`, `bank_units` through v_res. Copy-wise: 'bank: … 6 units' becomes '<side> up $60' — result-shaped, first names, no engine words, and it names who is holding rather than passively naming the pot ('$X on the line'). The 4-player transfer run-on ('Will pays Jerecho $20 · Isaak pays Jerecho $20 · Isaak pays Jade $10') collapses to one total once there are more than two payments; the detail belongs on the page's rows, not in a middot chain. 'Bragging rights only' is kept verbatim for the genuinely-no-money case — it is already the right string.

### `index.html`:15296 — broken  (115 → 40 chars)

**Now**

```
Sunningdale: Jerecho Fischbeck & Jade def. Will & Isaak 3&2 · no handicaps · bank: Jerecho Fischbeck & Jade 6 units
```

**Proposed**

```
Jerecho & Jade win 3&2
over Will & Isaak
```

**Source**

```js
<div style="font-family:${SERIF};font-size:30px;line-height:1.25;margin:16px 6px 0">${esc(head)}</div>
      ${sub ? `<div style="font-family:${SERIF};color:${C.mut};font-size:15px;margin:6px 6px 4px">${esc(sub)}</div>` : ''}
```

**Why** The page's 26px serif headline is the SAME 115-char run-on the owner texted, rendered verbatim from index.html:7186 — so Rule 5 fails in both directions: the message duplicated the page and the page added nothing. Stop rendering `r.story` here entirely (story stays the board-post line, a different surface with different constraints) and compose from structured fields: `const head = r.winner != null ? `${fnSide(r.winner === '0' ? r.side_a : r.side_b)} win ${String(r.status || '').toLowerCase()}` : 'All square'; const sub = r.winner != null ? `over ${fnSide(r.winner === '0' ? r.side_b : r.side_a)}` : `${fnSide(r.side_a)} · ${fnSide(r.side_b)}`;`. Result at character 1 instead of character 62; loser demoted to a quiet second line so the eye lands on '3&2'; 'no handicaps' dropped (the SUNNINGDALE RULES eyebrow already says it — the mode IS no handicaps); 'bank: … 6 units' dropped in favor of the money line's plain '<side> up $60'. Fix the source too: index.html:7186 and 7238 should say 'Sunningdale Rules' and drop '· no handicaps', so the board post and the card stop disagreeing.

### `index.html`:15287 — broken  (65 → 49 chars)

**Now**

```
Jerecho Fischbeck & Jade def. Will Hendricks & Isaak 2 UP THRU 14
```

**Proposed**

```
Jerecho & Jade win 2 up thru 14
over Will & Isaak
```

**Source**

```js
? `${fnSide(r.winner === '0' ? r.side_a : r.side_b) || String(r.status || 'Settled')} win ${String(r.status || '').toLowerCase()}`.replace(/^(\S.*) win $/, '$1').trim()
```

**Why** Four fixes in one line. (1) Full display names on both sides — `fnSide` reduces each '&'-joined side to first names; the cleanest place is upstream at matchResult()'s `names()` helper (index.html:7838) and sunnResult()'s (7176), which would fix side_a/side_b at write time so the card, the board post and the share sheet all inherit. (2) `r.status` from matchResult (7841-7842) is UPPERCASE — '2 UP THRU 14', 'HALVED' — a shouted fragment landing mid-sentence in a serif headline; lowercase it here and, better, stop upcasing at the source (the board post upcases on its own). '3&2' is unaffected, it has no letters. (3) 'def.' is scorecard shorthand; 'win' is what a person says. (4) The placeholder fallbacks 'Winners' and 'the other side' are deleted — when names are missing the score alone is still a result ('2 up thru 14'), and 'the other side' on a public card reads as a bug.

### `index.html`:15288 — broken  (68 → 40 chars)

**Now**

```
Jerecho Fischbeck & Jade and Will Hendricks & Isaak halved the match
```

**Proposed**

```
All square
Jerecho & Jade · Will & Isaak
```

**Source**

```js
: 'All square'
```

**Why** 'A and B and C and D' with an '&' inside each side is unparseable at a glance, and 'Settled on the course' is a last-resort headline on a card whose only job is to say who won — it says nothing at all. A halved match still has a result: nobody won. 'All square' is real golf, it is the result, it is 10 characters, and it works as the last-resort fallback too, so the empty-string branch disappears. The two sides move to the same quiet `sub` line the win branch uses (line 15296's template), separated by a middot rather than 'and' so the four names parse as two teams.

### `index.html`:15418 — broken  (119 → 61 chars)

**Now**

```
Will — 88 at Papago Golf Course · 2026-07-25. Enter your email, save your golfer card, and the round is yours for good.
```

**Proposed**

```
Will — 88 at Papago Golf Course. Enter your email to keep it.
```

**Source**

```js
const who  = data.guest_name ? fn(data.guest_name) + ' — ' : '';
        const what = [data.gross, data.course_label && 'at ' + data.course_label].filter(Boolean).join(' ');
        openEmailBox($('#obJoin'), what
          ? `${who}${what}. Enter your email to keep it.`
          : 'Your round is waiting. Enter your email to keep it.');
```

**Why** This is the first sentence a person who has never used Cup Season reads, and it currently greets them with a raw ISO date: `data.played_on` is interpolated unformatted, so the door says '· 2026-07-25'. It is the only public date on this surface that skips fmtD (15216) and therefore the only one exposed to the UTC-midnight landmine on the read side too — the fix is to drop the date from the greeting entirely (the course and score identify the round; the date is on the card behind the door) rather than plumb a formatter into module scope. Also: 117 chars and three separators before the ask; 'save your golfer card' is app vocabulary aimed at someone who does not yet know what a golfer card is (Rule 4) — 'keep it' needs no glossary; and the fallbacks 'Your card' and 'the course' can co-occur into 'Your card — the course. Enter your email…', so the no-data case gets its own whole sentence instead of assembling placeholders. `fn()` on guest_name because a scan partner row can carry a full name.

### `index.html`:15401 — broken  (87 → 47 chars)

**Now**

```
You're invited: code 7QK4M2. Enter your email and you'll join the league automatically.
```

**Proposed**

```
You're invited. Enter your email and you're in.
```

**Source**

```js
const inviteLine = n => n
      ? `You're invited to ${n}. Enter your email and you're in.`
      : `You're invited. Enter your email and you're in.`;
    openEmailBox($('#obJoin'), inviteLine(pendName));
```

**Why** The unresolved branch greets a human with a raw 6-char code as if it were a name — 'You're invited: code 7QK4M2' is a log line, not a greeting, and the code serves no purpose on screen since it is already in localStorage. Drop it. The resolved branch keeps its shape but trades 'and you'll join automatically' for 'and you're in' (55 chars, and it promises the outcome rather than describing the mechanism). The structural fix matters as much as the words: this sentence exists in FOUR places (15335, 15401, 15402, 13026-13027) and has already drifted three ways — 15335 omits 'the league', 13026 says 'the moment your sign-in code lands'. One `inviteLine()` helper, called from all four. And index.html:15334 currently gates the league-name warm-up on `/You're invited: code /.test(st.textContent)`, so ANY reword of 15402 silently kills name resolution on every /?join= link: replace the regex with a flag — set `st.dataset.csInvite = 'pending'` when openEmailBox renders the nameless variant, and test that instead.

### `index.html`:22 — confusing  (51 → 22 chars)

**Now**

```
Cup Season — season-long fantasy golf for your crew
```

**Proposed**

```
Jerecho & Jade win 3&2
```

**Source**

```js
<meta name="twitter:card" content="summary_large_image">
<meta property="og:site_name" content="Cup Season">
<meta name="twitter:title" content="${og.title || 'Cup Season'}">
<meta name="twitter:description" content="${og.desc || 'Rally your crew. Post real rounds. Take the cup.'}">
<meta name="twitter:image" content="${og.image || 'https://cupseason.app/og-image.png?v=3'}">
<meta name="twitter:image:alt" content="${og.title || 'Cup Season'}">
```

**Why** twitter:description is missing entirely (lines 22–24 define card/title/image only), so clients honoring twitter:* over og:* fall back inconsistently, and twitter:title duplicates og:title but not <title> — three one-liners for one page. Binding all three to the same `og.title`/`og.desc` makes drift structurally impossible. og:site_name is added because unfurls currently have no source attribution line; it also lets og:title stop spending characters on the brand name.

### `index.html`:15239 — confusing  (122 → 71 chars)

**Now**

```
Nothing here.
This link may have been revoked, or never was. Cup Season is season-long fantasy golf for real friend groups.
```

**Proposed**

```
This link is dead.
Whoever sent it can share a fresh one from the round.
```

**Source**

```js
document.title = 'Link expired · Cup Season';
    card.innerHTML = `<div style="font-size:15px;line-height:1.6;color:${C.ink};padding:16px 0 6px">This link is dead.</div>
      <div style="color:${C.mut};font-size:13px;line-height:1.6;padding-bottom:12px">Whoever sent it can share a fresh one from the round.</div>`;
```

**Why** 'or never was' is a fragment that reads as a typo to anyone not admiring the prose, and the paragraph then welds the dead-link explanation to the marketing tagline in one sentence. Worst, there is no recovery instruction — while the sibling dead path at index.html:15429 gets it exactly right, so copy that pattern verbatim rather than inventing a second one. The function returns at 15241 before any `document.title` assignment, so a dead share link is currently indistinguishable from the homepage in the tab bar; set it here. Also suppress the footer/CTA on this branch (see line 15236) — an ad under 'This link is dead' is the worst placement in the file.

### `index.html`:15237 — confusing  (24 → 24 chars)

**Now**

```
Start your crew's season
```

**Proposed**

```
Play this with your crew
```

**Source**

```js
const CTA = { round:'Post your own round', settlement:'Play this with your crew', recap:"Start your crew's season" };
    <a href="/" style="display:block;background:${C.hot};color:#1C1208;text-decoration:none;border-radius:12px;padding:14px 12px;font-weight:600;letter-spacing:.04em">${CTA[info.kind] || 'Open Cup Season'}</a>`;
```

**Why** Voice-correct but scale-wrong on two of three branches: the recipient of a settlement card is a player, not a Pro, and the button asks them to found a league — the largest possible commitment as the only door. Match the ask to what they just looked at: a settlement recipient wants this game with their own foursome, a round recipient wants their own card, a recap recipient is genuinely being pitched a season so the existing string is correct there and stays unchanged. The button goes to `/` in every case, where the door already offers a softer rung ('Peek at a live season', index.html:2362) that the public card never links to — worth surfacing as a secondary link rather than making the hard ask the only exit.

### `index.html`:15271 — confusing  (7 → 0 chars)

**Now**

```
A ROUND
```

**Proposed**

```

```

**Source**

```js
${info.course ? `<div style="letter-spacing:.12em;font-size:13px;margin-top:16px">${esc(String(info.course).toUpperCase())}</div>` : ''}
```

**Why** A placeholder shipped as content: where a course name belongs the card prints 'A ROUND' in the same letter-spaced treatment, which reads as missing data because it is. Drop the line when there is no course — the date line below still anchors the card, and an absent row is invisible while a wrong row is noise. Same family, same fix: 'A LEAGUE' (15309), 'A league' (15304), 'A golfer' (20260723230000:48/63), 'Winners' / 'the other side' (15287), 'Your card' / 'the course' (15418). None of the six should ever render.

### `index.html`:15272 — confusing  (21 → 19 chars)

**Now**

```
SAT · JUL 25 · 14 PTS
```

**Proposed**

```
SAT JUL 25 · 14 PTS
```

**Source**

```js
<div style="color:${pub ? 'rgba(240,242,243,.75)' : C.mut};font-size:11.5px;letter-spacing:.12em;margin-top:8px">${esc(fmtD(info.played_on))}${info.points != null ? ` · <span style="color:${C.warm}">${esc(String(info.points))} PTS</span>` : ''}</div>
```

**Why** The separator is doing two different jobs in one 11.5px line: fmtD (15221) already emits its own internal middot, so the reader cannot tell which middot separates day-from-date and which separates date-from-points. Drop the internal one — change fmtD's return to `${DW[d.getDay()]} ${MO[d.getMonth()]} ${d.getDate()}` — and the outer middot becomes unambiguous. This also improves the recap range (line 15310), which currently renders four separators in one line. Keeping '14 PTS' as-is: a bare points figure has no receipt path on a public page, but the band line directly above already tells a stranger whether the round was good, so the number is a secondary fact and does not need §16's proof trail here.

### `index.html`:15299 — confusing  (66 → 40 chars)

**Now**

```
Jerecho Fischbeck 84
Jade Morrow 91
Will Hendricks —
Isaak Bell 88
```

**Proposed**

```
Jerecho 84
Jade 91
Will no card
Isaak 88
```

**Source**

```js
${(() => { const win = new Set(String(r.winner === '0' ? r.side_a : r.side_b || '').split(' & ').map(fn)); return info.players.map(p => `<div style="display:flex;justify-content:space-between;padding:5px 12px;font-size:13.5px;${win.has(fn(p.name)) ? `color:${C.gold};font-weight:600` : ''}"><span>${esc(fn(p.name))}</span><span style="color:${C.mut}">${p.gross != null ? esc(String(p.gross)) : 'no card'}</span></div>`).join(''); })()}
```

**Why** Four full legal names stacked (share_info: `coalesce(pr.display_name, p.guest_name, 'A golfer')`), reduced by the shared `fn()`. The em dash for a player who never posted is unexplained — a recipient reads it as a broken row, not 'didn't post'; 'no card' is seven characters and says the actual thing. And the visual half of the card does not reinforce the result at all: gold-weighting the winning side's rows is the 'more visuals' answer at zero copy cost, and it means the score block confirms the headline instead of sitting beside it. `r.winner`/`r.side_a` are already in scope from line 15282.

### `index.html`:15304 — confusing  (30 → 44 chars)

**Now**

```
PIGL — the season · Cup Season
```

**Proposed**

```
The Antelopes took the PIGL cup · Cup Season
```

**Source**

```js
document.title = (info.champion
      ? `${info.champion} took the ${info.league || ''} cup`.replace(/\s+/g,' ').trim()
      : `${info.league || 'The'} season so far`) + ' · Cup Season';
```

**Why** 'the season' as the whole predicate carries no state — a finished season and a live one title identically, which is the one thing the recipient of a recap link wants to know. Lead with the champion when there is one (Rule 2); fall back to 'PIGL season so far' when there isn't, which states the live state without the indefinite-article placeholder 'A league'. Same JS-only limitation as line 15245 — feed this composition to the edge function so it actually reaches the unfurl.

### `index.html`:15311 — confusing  (29 → 26 chars)

**Now**

```
🏆 THE ANTELOPES TAKE THE CUP
```

**Proposed**

```
The Antelopes took the cup
```

**Source**

```js
${info.champion ? `<div style="font-family:${SERIF};color:${C.gold};font-size:26px;line-height:1.3;margin:14px 6px 0">${esc(String(info.champion))} took the cup</div>` : ''}
```

**Why** Three problems. Emoji in body copy on a public artifact card — Rule 6 allows emoji only as leading glyphs in board rows, and this is the ceremonial line on a season's public page. Present tense 'TAKE THE CUP' contradicts the 'FINAL' status rendered eleven lines down. And it is the result line of a recap sitting BELOW the league name and the date range (Rule 2). Fix all three by promoting it to the card's headline slot in the same 26px serif the settlement card uses, in sentence case — the recap card's order becomes eyebrow (league) → headline (champion) → range → rows → status, which is the same shape as the settlement card and reads as one system.

### `index.html`:15312 — confusing  (31 → 27 chars)

**Now**

```
POINTS KING · JERECHO FISCHBECK
```

**Proposed**

```
POINTS KING · JERECHO · 412
```

**Source**

```js
${info.points_king ? `<div style="color:${C.mut};font-size:12px;letter-spacing:.1em;margin-top:6px">POINTS KING · ${esc(fn(String(info.points_king)).toUpperCase())}${info.points_king_points != null ? ` · ${esc(String(info.points_king_points))}` : ''}</div>` : ''}
```

**Why** 'POINTS KING' stays — it is a ceremonial title a friend group actually enjoys, it already appears in the pot-split UI (index.html:3107, 10027), and renaming it here would fork the vocabulary. The real defects are the full display name (share_info pulls `profiles.display_name`, 20260723230000:107 — `fn()` fixes it) and the missing number: the honor is unverifiable on a page whose entire promise is proof. Requires share_info to return the king's point total alongside the name — add `'points_king_points'` to the recap jsonb_build_object, sourced from v_individual_standings for `s.points_king_member_id`.

### `index.html`:15314 — confusing  (24 → 22 chars)

**Now**

```
The table is warming up.
```

**Proposed**

```
Nobody posted a round.
```

**Source**

```js
${rows || `<div style="color:${C.mut};font-size:13px;padding:10px 0">${info.status === 'complete' ? 'Nobody posted a round.' : 'The table is warming up.'}</div>`}
```

**Why** The string itself is voice-correct and short and is kept verbatim for live seasons — no churn. The only defect is the contradiction: a completed season with zero standings rows renders 'FINAL' in the footer and 'The table is warming up' in the body. Branch on the same status the footer already reads. 'Nobody posted a round.' states the actual fact without blame or engine words.

### `manifest.webmanifest`:4 — confusing  (44 → 48 chars)

**Now**

```
Season-long fantasy golf with your own crew.
```

**Proposed**

```
Rally your crew. Post real rounds. Take the cup.
```

**Source**

```js
"description": "Rally your crew. Post real rounds. Take the cup.",
  "categories": ["sports", "games"],
```

**Why** The fourth variant of one sentence — index.html:25 'with your own crew', :14 'for your real crew', :15/:23 'for your crew', here 'with your own crew.' Three prepositions, three qualifiers, one product. Adopt the door hero (index.html:2342) as the single tagline across all four so drift is impossible. `name` and `short_name` are both 'Cup Season' (lines 2-3) and that is correct — short_name stays under 12 chars. Adding `categories` costs one line and helps app-directory placement; the missing `screenshots` key is the same emptiness as the og:image problem one surface over — the install prompt has no visual, so the first-run pitch is a bare icon.

### `index.html`:14 — wordy  (176 → 48 chars)

**Now**

```
Season-long fantasy golf for your real crew — draft squads, post the rounds you actually play from any course, and settle it in a Cup Final. Every dollar of the pot on the books.
```

**Proposed**

```
Rally your crew. Post real rounds. Take the cup.
```

**Source**

```js
<meta name="description" content="${og.desc || 'Rally your crew. Post real rounds. Take the cup.'}">
```

**Why** 176 chars, three clauses, and product vocabulary ('draft squads', 'Cup Final', 'the pot') aimed at a buyer. The strongest public line in the repo is already written at index.html:2342 — the door hero — and appears in zero metadata. Adopt it verbatim as the single fallback tagline everywhere (this line, og:description line 16, twitter:description, manifest.webmanifest:4), which collapses the four drifting variants ('with your own crew' / 'for your real crew' / 'for your crew' / 'with your own crew.') into one sentence. Per-token, this tag takes the same `og.desc` as og:description so a scraper that ignores og:* still gets the real news.

### `index.html`:15236 — wordy  (47 → 36 chars)

**Now**

```
Built with Cup Season — real rounds, real crews
```

**Proposed**

```
Cup Season — real rounds, real crews
```

**Source**

```js
if(info && info.kind) foot.innerHTML = `<div style="color:${C.mut};font-size:12px;letter-spacing:.08em;margin-bottom:12px">Cup Season — real rounds, real crews</div>
```

**Why** 'Built with' is SaaS-badge register borrowed from 'Built with Framer' — the card wasn't built, the round was played. Dropping two words fixes it; the rest of the line is voice-correct. The structural fix matters more: `foot.innerHTML` is assigned before the `if(!info || !info.kind)` guard at 15238, so the footer and CTA render on the dead-link card too, where they read as an ad for a broken page. Gate the assignment on a resolved payload.

### `index.html`:15245 — wordy  (57 → 50 chars)

**Now**

```
Jerecho Fischbeck — 84 at Papago Golf Course · Cup Season
```

**Proposed**

```
Jerecho shot 84 at Papago Golf Course · Cup Season
```

**Source**

```js
document.title = `${fn(info.name)} shot ${info.gross} at ${info.course} · Cup Season`;
```

**Why** The shape is right and the placement is wrong — this is the proof that a per-share <title> was wanted and never reached the head. Crawlers do not run JS, so it only ever reaches a human already on the page; feed the same composition to the edge function (line 15) and this line becomes the client-side mirror of `og.title`. Copy fixes: `fn()` reduces share_info's `coalesce(profiles.display_name,'A golfer')` to a first name (Rule 3), and the em dash becomes 'shot', which is how a person says it out loud.

### `index.html`:15265 — wordy  (17 → 7 chars)

**Now**

```
JERECHO FISCHBECK
```

**Proposed**

```
JERECHO
```

**Source**

```js
<div style="letter-spacing:.18em;font-size:16px;font-weight:600">${esc(fn(String(info.name)).toUpperCase())}</div>
```

**Why** Full legal name, uppercased and letter-spaced — the most formal possible rendering of the thing Rule 3 bans, on a card the golfer chose to broadcast to friends. share_info hands over `display_name` whole (20260723230000:48) and no first-name helper exists on any public path, so add the shared reducer `const fn = s => String(s||'').trim().split(/\s+/)[0];` near fmtD (index.html:15216) and apply it at 15265, 15287, 15288, 15299 and 15312. Alternative worth considering: reduce in SQL with `split_part(coalesce(pr.display_name,…), ' ', 1)` so no full name ever crosses the wire to an anon caller — a small privacy win on a public endpoint, at the cost of losing the full name if a surface ever wants it.

### `index.html`:15310 — wordy  (39 → 14 chars)

**Now**

```
THE SEASON · WED · JAN 7 — SUN · JUN 28
```

**Proposed**

```
JAN 7 — JUN 28
```

**Source**

```js
<div style="color:${C.mut};font-size:11.5px;letter-spacing:.14em;margin-top:8px">${esc(fmtMD(info.starts_on))} — ${esc(fmtMD(info.ends_on))}</div>
```

**Why** Four separators in one line: fmtD emits 'DAY · MON D' so the range stacks two internal middots against an em dash. Weekday names on a season range are pure noise — nobody needs to know the season started on a Wednesday — so this line takes a weekday-less formatter (`const fmtMD = iso => { const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso||''); return m ? `${MO[+m[2]-1]} ${+m[3]}` : ''; }`, same manual parse to stay clear of the `new Date('YYYY-MM-DD')` UTC landmine). 'THE SEASON ·' is dropped: the card's eyebrow already names the league and the footer already says FINAL or IN PLAY, so the label restates two neighbors.

### `index.html`:15315 — wordy  (18 → 7 chars)

**Now**

```
STILL BEING PLAYED
```

**Proposed**

```
IN PLAY
```

**Source**

```js
<div style="color:${C.mut};font-size:11px;letter-spacing:.1em;margin-top:12px">${info.status === 'complete' ? 'FINAL' : info.status === 'cup_final' ? 'CUP FINAL' : 'IN PLAY'}</div>
```

**Why** Passive voice and 18 characters for a state that 'IN PLAY' covers in seven, sitting next to a four-character sibling ('FINAL') in the same slot — the asymmetry alone makes it read as unfinished. Worse, it is binary on a three-state model: seasons also carry `cup_final` (CLAUDE.md — the daily tick flips seasons.status at ends_on−27), which currently flattens the most dramatic phase of the season into the generic in-progress label. Naming it costs nothing and is the one status a recipient would actually click through for.

### `index.html`:13001 — wordy  (31 → 12 chars)

**Now**

```
$50 / player · on the pot sheet
```

**Proposed**

```
$50 / player
```

**Source**

```js
<div class="byrow"><span>BUY-IN</span><b>$${usd} / player</b></div>
      ${info.preset?`<div class="byrow"><span>PRESET</span><b>${esc(String(info.preset).replace(/^./,c=>c.toUpperCase()))}</b></div>`:''}
      ${Number(info.floor)?`<div class="byrow"><span>EACH MONTH</span><b>${info.floor} round${Number(info.floor)===1?'':'s'} to stay in</b></div>`:''}
```

**Why** 'on the pot sheet' is internal vocabulary appearing one line ABOVE the sentence at 13005 that explains it ('Cup Season keeps the tab; money moves between you') — the jargon precedes its own gloss, so a first-time reader hits it cold. Drop it; the gloss survives and does the work. Second fix in the same sheet: 'PARTICIPATION FLOOR' (13003) is raw engine vocabulary on the first screen a new member reads, and CLAUDE.md bans floors/caps language from outbound copy — 'EACH MONTH · 2 rounds to stay in' says the same rule in words a person uses, and 'to stay in' supplies the consequence that 'FLOOR' was hiding. The sheet is otherwise honest and correctly ordered: money is named before the commitment, which is the right instinct and should not change.

### `index.html`:15211 — fine  (17 → 17 chars)

**Now**

```
Opening the card…
```

**Proposed**

```
Opening the card…
```

**Source**

```js
<div style="color:${C.mut};font-size:13px;padding:34px 0">Opening the card…</div>
```

**Why** Fine as written — short, plain, no jargon. Recording it because it is the page's true static body: a JS-disabled fetch, and any crawler-adjacent scraper that reads the DOM rather than og:*, sees only this. That is a second argument for the edge-function fix at line 15 — the injected head should also seed a plain-text result line in the initial HTML so the page is not literally blank of news before JS runs. No change to the string.

### `index.html`:15268 — fine  (35 → 35 chars)

**Now**

```
TORCHED IT
beat their number by 3.2
```

**Proposed**

```
TORCHED IT
beat their number by 3.2
```

**Source**

```js
${pviSane ? `<div style="color:${C.hot};letter-spacing:.16em;font-size:14.5px;font-weight:600;margin-top:10px">${esc(theirs(bandName(Number(info.pvi))).toUpperCase())}</div>
      <div style="font-family:${SERIF};color:${pub ? 'rgba(240,242,243,.85)' : C.mut};font-size:14px;margin-top:6px">${esc(theirs(vsPhrase(Number(info.pvi))))}</div>` : ''}
```

**Why** No change. This is the model the settlement branch should be rewritten toward and now is: a named band as the loud line, one plain sentence under it, third person handled correctly by `theirs()` (index.html:5132), zero engine words, and the result leads. The only open question is upstream and out of scope for this surface: bandName's low bands (index.html:5118-5119, 'A little loose' / 'Posted anyway') are gentle in-app but read as faint criticism on a card the golfer chose to broadcast — changing them touches every in-app receipt, so it belongs in a scoring-language pass, not here.

### `index.html`:15429 — fine  (108 → 108 chars)

**Now**

```
That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round.
```

**Proposed**

```
That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round.
```

**Source**

```js
authStatus('That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round.', 'err');
```

**Why** No change. Two clauses, plain language, and it names the recovery — the only dead-end string on this surface that tells the visitor what to do next, which is why line 15239 should be rewritten to copy it rather than the other way round. It is 108 characters, but this is page copy read while standing still, not share-sheet text read in a moving thread, so the length budget in Rule 1 does not bind. The one nit — 'from the round' assumes the sender knows where the re-share control lives — is real but tightening it ('…can share a fresh one') costs the sender the only pointer they get, so leave it.

### `index.html`:2342 — fine  (48 → 48 chars)

**Now**

```
Rally your crew.
Post real rounds.
Take the cup.
```

**Proposed**

```
Rally your crew.
Post real rounds.
Take the cup.
```

**Source**

```js
<h1>Rally your crew.<br>Post real rounds.<br><em>Take the cup.</em></h1>
```

**Why** No change — three beats, twelve words, verbs first, no hype, no product vocabulary. It is the strongest public-facing line in the repo and every metadata tag on this surface ignores it in favor of a category description. That is the gap: the door says this and the link preview says 'season-long fantasy golf for your crew'. Under the rewrites above this line becomes the single static fallback for og:description, meta description and manifest.webmanifest, so the four drifting taglines collapse into the one sentence that was already right.

### `index.html`:2362 — fine  (21 → 21 chars)

**Now**

```
Peek at a live season
```

**Proposed**

```
Peek at a live season
```

**Source**

```js
<button class="btn dark" id="obDemo" style="margin-top:10px">Peek at a live season</button>
```

**Why** No change — 21 chars, correct voice, and 'peek' honestly sizes the commitment. Flagged only for the mismatch it exposes: the door offers this soft rung and the public share card's sole CTA (line 15237) is the hardest possible ask. The share card should link here as a secondary exit, not send every settlement recipient at founding a league.

### `index.html`:14860 — fine  (133 → 133 chars)

**Now**

```
You can't hurt your squad by playing badly. Only by not playing. Every posted round scores — a rough day is still points on the board.
```

**Proposed**

```
You can't hurt your squad by playing badly. Only by not playing. Every posted round scores — a rough day is still points on the board.
```

**Source**

```js
<p class="fine" style="padding:0 0 10px"><b style="color:var(--pos)">You can't hurt your squad by playing badly.</b> Only by not playing. Every posted round scores — a rough day is still points on the board.</p>
```

**Why** No change. The bolded lead clause is the house register benchmark: it states the reader's actual fear and kills it in nine words, then the sentences shorten as they go ('Only by not playing.' is four). Result first, plain vocabulary, no hype, no exclamation. This is what the settlement card's headline should sound like and, after the line 15296 rewrite, finally does.

### `index.html`:15185 — fine  (115 → 115 chars)

**Now**

```
You're unsubscribed
No more season-end emails. Your league and your rounds are untouched — this only stops the mail.
```

**Proposed**

```
You're unsubscribed
No more season-end emails. Your league and your rounds are untouched — this only stops the mail.
```

**Source**

```js
<div style="font-family:Georgia,serif;font-size:26px;margin:16px 0 8px">${ok?'You&rsquo;re unsubscribed':'That link has expired'}</div>
      <p style="color:#8E979E;font-size:13px;line-height:1.6;margin:0 0 20px">${ok
        ? 'No more season-end emails. Your league and your rounds are untouched — this only stops the mail.'
        : 'Nothing changed. You can turn season emails off any time from the app.'}</p>
```

**Why** No change to the copy. Result first, one clause of reassurance, and it pre-empts the exact fear an unsubscriber has (that they just left the league) without hype — the only public takeover on this surface that gets the shape right, and the model for the dead-link card at 15239. Two adjacent non-copy notes: the CTA below reads 'Open Cup Season' (15189) and an unsubscriber is the single visitor least likely to want that, so it should be a quiet text link rather than the one filled button on the screen; and this block uses `Georgia,serif` while the share card at 15204 uses the `'Charter','Iowan Old Style'` stack — two serif identities across two public takeovers, worth unifying on the share card's stack.

---

## Rename: Sunningdale → Sunningdale Rules

### Database

The live_rounds game CHECK ALREADY allows 'sunningdale'. Latest migration touching it is C:\Users\17203\Downloads\cup-season\supabase\migrations\20260725220000_sunningdale_game.sql:22-24 (commit 0ac0f52, D74) — nothing after it alters the constraint (verified against all 100 migrations; the only other touches are 00000000000000_initial_baseline.sql:1154 and 20260716140000_wolf_skins_claim.sql:26-28). The live array, quoted exactly:

  alter table public.live_rounds drop constraint live_rounds_game_check;
  alter table public.live_rounds add constraint live_rounds_game_check
    check (game = any (array['none'::text,'match'::text,'wolf'::text,'skins'::text,'sunningdale'::text]));

YES, 'sunningdale' is in it, added by 20260725220000_sunningdale_game.sql. The mode persists in TWO places, both as the lowercase key 'sunningdale': (1) live_rounds.game, written by start_live_round from index.html:7805 `p_game:(game==='score'?'none':game)`; (2) inside the live_rounds.game_result JSONB, set client-side at index.html:7187 `return { game:'sunningdale', ...` and index.html:7235 `return { game:'sunningdale', mode:'solo', ...`, which the server branches on in the CURRENT finish_live_round at supabase\migrations\20260726120000_match_story_override.sql:128 `elsif (p_result->>'game') in ('wolf','skins','sunningdale') then` (superseding the identical line at 20260725220000_sunningdale_game.sql:139).

THE RENAME REQUIRES NO MIGRATION. It is label-only in the client. Every rename target is a display string in index.html; not one of them is compared, stored, or sent to the database. Nine lines change; the stored key 'sunningdale' does not move.

### Scope and risk

TOTAL: 95 grep hits across 8 files. 94 real; 1 false positive (supabase/functions/weather/index.ts:30 is "Mostly sunny", unrelated).

BREAKDOWN: 9 lines to rename (all user-facing labels in index.html) · 30 stored-key comparisons/writes (leave) · 33 internal identifiers (leave) · 22 comments/spec prose (leave).

THE 9 RENAME LINES, all in C:\Users\17203\Downloads\cup-season\index.html: 2693 (game picker button text), 7185 + 7186 (the 2-sided settlement story — line 7186 is EXACTLY the string the owner texted), 7238 (solo settlement story), 7403 (live match-card header, solo), 7419 + 7420 (live match-card header, singles / 2v2), 7523 (tee-off preview fallback), 7743 (roster-size toast).

VERDICT ON TOUCHING THE DATABASE: don't. A migration for a display string would be a bad trade, and here it is worse than usual — the key lives in THREE places that would all need to move together: (a) the CHECK constraint, (b) every existing live_rounds.game value, (c) the `game` field inside every stored live_rounds.game_result JSONB, which the server branches on at 20260726120000_match_story_override.sql:128. And (d) already-posted board rows in `posts` are immutable free text by design (spec §16), so historical settlement stories could never be back-renamed anyway. The stored key 'sunningdale' is never shown to a user; it is only ever compared. Leave it.

THREE LABEL MAPS THAT OMIT THE MODE ENTIRELY — these contain no "sunn" so grep missed them, and one is directly implicated in the owner's complaint:
1. index.html:15283 — `const GAME = { match:'MATCH PLAY', wolf:'WOLF', skins:'SKINS', none:'THE ROUND' };` feeding line 15284 `document.title = \`${GAME[info.game] || 'Settlement'} at ${info.course} · Cup Season\`` and line 15295 `${esc(GAME[info.game] || 'SETTLED')}`. For a Sunningdale settlement the public share page's eyebrow reads "SETTLED" and the tab title reads "Settlement at <course>". The page the group taps never names the game. Add the 'sunningdale' entry when renaming.
2. index.html:7011 — `const gl={score:'Stroke play', match:'Match play', wolf:'Wolf', skins:'Skins'}[L.game]||'Live round';` — the Continue-your-round banner shows "LIVE ROUND" for a Sunningdale round instead of the game name.
3. index.html:7949 and 7961 — showLiveRecap branches on `result.game==='match'` then `(result.game==='wolf' || result.game==='skins')`. 'sunningdale' matches NEITHER, so the finish recap sheet renders no settlement headline row at all — the "who won and by how much" line is simply absent from the recap.

WHERE THE BAD TEXT ACTUALLY COMES FROM (for the copy fix that follows this rename): index.html:7186 builds the story, and index.html:7987 passes it to the share sheet as `(result?.story || \`${result?.side_a || 'The match'} vs ${result?.side_b || ''}\`).slice(0,120)` — that `.slice(0,120)` is the 120-char cap the owner hit. The SAME string is sent to the server as p_result.story and inserted into `posts` via `left(p_result->>'story', 200)` (20260726120000_match_story_override.sql:131-133). So one edit at 7186 fixes both the text message and the board post, with no db push. Full names come from `LIVE[i].n` via `names()` at index.html:7176 — first-name shortening belongs there, not in the story template, so match/wolf/skins/RR stories inherit it. The percent-encoding the owner saw is the OS share handler encoding `&` and `·` from `navigator.share({title, text, url})` at index.html:5277 — another argument for dropping `&` and `·` from the share string.

CASING: stories ship natural-case per the 2026-07-24 casing policy (20260725220000_sunningdale_game.sql:13-15); easeCaps passes mixed case straight through, so "Sunningdale Rules" survives intact. But the LIVE CARD lines at 7403/7419/7420 are consumed by upper-casing siblings (7405, 7415, 7423) and the card renders SCREAMING CAPS — "SUNNINGDALE RULES · 2V2 BEST BALL" is longer than what fits; check overflow after the rename.

ENCODING LANDMINE: lines 7185, 7186, 7238, 7403, 7419, 7420 all carry the real UTF-8 `·`, and CLAUDE.md warns index.html has MIXED middot encodings. Anchor any Edit on adjacent ASCII-only text rather than matching through a middot.

FUNCTION NAMES MUST NOT MOVE: tests/sunningdale.test.mjs extracts the engines by literal string index — line 25 `html.indexOf('function sunnEngine(')` and line 147 `html.indexOf('function sunnSoloEngine(')`. Renaming sunnEngine/sunnSoloEngine breaks CI hard (.github/workflows/ci.yml:57-58 runs it on every push). Likewise the two FILENAMES stay: tests/sunningdale.test.mjs is wired into ci.yml:58 and .claude/settings.json:24, and supabase/migrations/20260725220000_sunningdale_game.sql can never be renamed — CLAUDE.md rule 2, migrations are never edited after running in production.

SPEC: the 7 decision-log entries (D74/D75) are historical prose and stay as written. Per CLAUDE.md rule 5 the rename itself is a UI-level change, not a mechanic change, so it needs no new decision-log entry — but a one-line note under D74 recording the display name would be cheap and would stop a future session "fixing" the label back.

### Every occurrence

| file | line | kind | action | text |
|---|---|---|---|---|
| index.html | 2693 | user-facing-label | **rename-label-only** | `<button data-g="sunningdale">Sunningdale</button>` |
| index.html | 6603 | comment | **leave** | `   everyone for themselves (match = round-robin singles · sunningdale = solo,` |
| index.html | 6880 | stored-key | **leave** | `if(game==='match' \|\| game==='sunningdale'){   /* both carry side_a/side_b in cfg */` |
| index.html | 6891 | comment | **leave** | `state.live = { stage:'live', active:true, game, stake:Number(cfg.stake ?? cfg.unit)\|\|0, wolfOrder,   /* sunningdale's cfg calls it unit */` |
| index.html | 7099 | comment | **leave** | `/* Sunningdale (D74): match play with NO handicaps — the equalizer is` |
| index.html | 7104 | comment | **leave** | `   tests/sunningdale.test.mjs (TDD, written red first); sunnCalc() below is the` |
| index.html | 7106 | internal-identifier | **leave** | `function sunnEngine(inp){` |
| index.html | 7125 | comment | **leave** | `/* D75 · solo Sunningdale (everyone for themselves) — OUR extension of the` |
| index.html | 7131 | comment | **leave** | `   tested in tests/sunningdale.test.mjs (TDD, red first). */` |
| index.html | 7132 | internal-identifier | **leave** | `function sunnSoloEngine(inp){` |
| index.html | 7158 | internal-identifier | **leave** | `function sunnCalc(){` |
| index.html | 7159 | internal-identifier | **leave** | `  return sunnEngine({ scores:state.live.scores, teams:MTEAMS, holes:liveHoles() });` |
| index.html | 7161 | internal-identifier | **leave** | `function sunnSoloCalc(){` |
| index.html | 7162 | internal-identifier | **leave** | `  return sunnSoloEngine({ scores:state.live.scores, holes:liveHoles() });` |
| index.html | 7164 | internal-identifier | **leave** | `function sunnSoloStrokesAt(h){` |
| index.html | 7166 | internal-identifier | **leave** | `  return sunnSoloEngine({ scores:cut, holes:liveHoles() }).strokes;` |
| index.html | 7170 | internal-identifier | **leave** | `function sunnStrokesAt(h){` |
| index.html | 7172 | internal-identifier | **leave** | `  return sunnEngine({ scores:cut, teams:MTEAMS, holes:liveHoles() }).strokes;` |
| index.html | 7174 | internal-identifier | **leave** | `function sunnResult(){` |
| index.html | 7175 | internal-identifier | **leave** | `  const m=sunnCalc();` |
| index.html | 7185 | user-facing-label | **rename** | `    ? `Sunningdale: ${names(0)} and ${names(1)} halved it · ${bankTxt}`` |
| index.html | 7186 | user-facing-label | **rename** | `    : `Sunningdale: ${names(winner)} def. ${names(winner===0?1:0)} ${status} · no handicaps · ${bankTxt}`;` |
| index.html | 7187 | stored-key | **leave** | `  return { game:'sunningdale', winner: winner==null?null:String(winner), status,` |
| index.html | 7226 | comment | **leave** | `/* D75 · solo Sunningdale result — the bank names its owner; liability is per` |
| index.html | 7229 | internal-identifier | **leave** | `function sunnSoloResult(){` |
| index.html | 7230 | internal-identifier | **leave** | `  const m=sunnSoloCalc(), unit=state.live.stake\|\|0;` |
| index.html | 7235 | stored-key | **leave** | `  return { game:'sunningdale', mode:'solo', unit, thru:m.played,` |
| index.html | 7238 | user-facing-label | **rename** | `    story:`Sunningdale, everyone for themselves: ${line} · no handicaps · ${bankTxt}` };` |
| index.html | 7315 | stored-key | **leave** | `$('#matchCard').style.display = (state.live.game==='match'\|\|state.live.game==='sunningdale') ? 'block':'none';` |
| index.html | 7343 | stored-key | **leave** | `        state.live.game==='sunningdale'` |
| index.html | 7344 | internal-identifier | **leave** | `          ? (liveSolo() ? (sunnSoloStrokesAt(h)[pi]\|\|0)` |
| index.html | 7345 | internal-identifier | **leave** | `                        : (sunnStrokesAt(h)[MTEAMS[0].includes(pi)?0:1]\|\|0))   /* D74/D75: positional strokes, not SI */` |
| index.html | 7347 | stored-key | **leave** | `      <small>${state.live.game==='sunningdale' ? 'NO HCP · STRAIGHT UP' : `${p.est?'EST ':(p.guest?'SELF ':'')}${fmtIdx(p.i)} IDX · ${STROKES[pi]} STK`}</small>` |
| index.html | 7400 | comment | **leave** | `  /* D75: solo Sunningdale — the leaderboard, the field's strokes, the bank */` |
| index.html | 7401 | stored-key | **leave** | `  if(state.live.game==='sunningdale' && liveSolo() && LIVE.length===4){` |
| index.html | 7402 | internal-identifier | **leave** | `    const m=sunnSoloCalc(), unit=state.live.stake\|\|0;` |
| index.html | 7403 | user-facing-label | **rename** | `    $('#matchTeams').textContent='Sunningdale · everyone for themselves';` |
| index.html | 7412 | comment | **leave** | `  /* D74: Sunningdale shares the match card — same shape, different law. The` |
| index.html | 7414 | stored-key | **leave** | `  if(state.live.game==='sunningdale'){` |
| index.html | 7419 | user-facing-label | **rename** | `      ? `Sunningdale · singles · ${LIVE[0]?.n\|\|''} vs ${LIVE[1]?.n\|\|''}`` |
| index.html | 7420 | user-facing-label | **rename** | `      : `Sunningdale · 2v2 best ball · ${sideStr(0)} vs ${sideStr(1)}`;` |
| index.html | 7421 | internal-identifier | **leave** | `    const m=sunnCalc();` |
| index.html | 7511 | stored-key | **leave** | `  const money = g==='match'\|\|g==='wolf'\|\|g==='skins'\|\|g==='sunningdale';` |
| index.html | 7517 | stored-key | **leave** | `    : g==='sunningdale' ? 'Bank unit · $0 = bragging rights'` |
| index.html | 7519 | stored-key | **leave** | `  if(g==='sunningdale'){` |
| index.html | 7523 | user-facing-label | **rename** | `      : 'Sunningdale takes 2 (singles) or 4 (2v2 best ball).';` |
| index.html | 7573 | stored-key | **leave** | `  const teamable = (state.live.game==='match'\|\|state.live.game==='sunningdale')` |
| index.html | 7729 | stored-key | **leave** | `    sunningdale:'Match play, no handicaps — go 2 down and you get a stroke until you climb out. Singles or 2v2. Win a hole while ahead to bank a unit.'};` |
| index.html | 7737 | stored-key | **leave** | `    : (g==='match'\|\|g==='sunningdale') ? (sel.length!==2 && sel.length!==4)` |
| index.html | 7743 | user-facing-label | **rename-label-only** | `      : g==='sunningdale' ? 'Sunningdale takes 2 (singles) or 4 (2v2)'` |
| index.html | 7753 | stored-key | **leave** | `  const _mode=((game==='match'\|\|game==='sunningdale') && LIVE.length===4)` |
| index.html | 7755 | stored-key | **leave** | `  if((game==='match'\|\|game==='sunningdale') && LIVE.length===4 && _mode!=='solo'){` |
| index.html | 7762 | stored-key | **leave** | `  const stake = (game==='match'\|\|game==='wolf'\|\|game==='skins'\|\|game==='sunningdale')` |
| index.html | 7797 | stored-key | **leave** | `        : game==='sunningdale'` |
| index.html | 7872 | stored-key | **leave** | `  if(state.live.game==='sunningdale' && liveSolo() && LIVE.length===4) return sunnSoloResult();` |
| index.html | 7876 | stored-key | **leave** | `  if(state.live.game==='sunningdale' && (LIVE.length===2\|\|LIVE.length===4)) return sunnResult();` |
| 20260725220000_sunningdale_game.sql | 2 | comment | **leave** | `-- Cup Season — D74: Sunningdale joins the tee sheet` |
| 20260725220000_sunningdale_game.sql | 6 | comment | **leave** | `-- layer. The game engine is fully client-side (sunnEngine, TDD:` |
| 20260725220000_sunningdale_game.sql | 7 | comment | **leave** | `-- tests/sunningdale.test.mjs); the server needs exactly two things:` |
| 20260725220000_sunningdale_game.sql | 9 | comment | **leave** | `--   1. live_rounds' game CHECK learns the value 'sunningdale'` |
| 20260725220000_sunningdale_game.sql | 15 | comment | **leave** | `-- upper()-ing its parts and the wolf/skins/sunningdale story ships as sent.` |
| 20260725220000_sunningdale_game.sql | 17 | comment | **leave** | `-- easing as before. Skew-safe: an old client never sends game='sunningdale'` |
| 20260725220000_sunningdale_game.sql | 24 | stored-key | **leave** | `  check (game = any (array['none'::text,'match'::text,'wolf'::text,'skins'::text,'sunningdale'::text]));` |
| 20260725220000_sunningdale_game.sql | 139 | stored-key | **leave** | `    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then` |
| 20260726120000_match_story_override.sql | 6 | comment | **leave** | `-- story (per-player records), exactly as wolf/skins/sunningdale already do.` |
| 20260726120000_match_story_override.sql | 128 | stored-key | **leave** | `    elsif (p_result->>'game') in ('wolf','skins','sunningdale') then` |
| sunningdale.test.mjs | 1 | comment | **leave** | `// Cup Season — Sunningdale engine tests (D74). TDD: this file was written RED,` |
| sunningdale.test.mjs | 3 | comment | **leave** | `// implementation was written. Run: node tests/sunningdale.test.mjs` |
| sunningdale.test.mjs | 5 | comment | **leave** | `// sunnEngine is a PURE function in index.html (classic block) — extracted here` |
| sunningdale.test.mjs | 8 | comment | **leave** | `//   sunnEngine({ scores, teams, holes })` |
| sunningdale.test.mjs | 25 | internal-identifier | **leave** | `const at = html.indexOf('function sunnEngine(');` |
| sunningdale.test.mjs | 27 | internal-identifier | **leave** | `  console.error('FAIL — sunnEngine not found in index.html (engine not implemented)');` |
| sunningdale.test.mjs | 37 | internal-identifier | **leave** | `const sunnEngine = new Function(`${src}; return sunnEngine;`)();` |
| sunningdale.test.mjs | 48 | internal-identifier | **leave** | `const singles = (sa, sb, holes = 18) => sunnEngine({ scores: [sa, sb], teams: [[0], [1]], holes });` |
| sunningdale.test.mjs | 86 | internal-identifier | **leave** | `  const r = sunnEngine({` |
| sunningdale.test.mjs | 141 | comment | **leave** | `/* ===================== D75 · solo Sunningdale (everyone for themselves) =====` |
| sunningdale.test.mjs | 142 | comment | **leave** | `   sunnSoloEngine({scores, holes}) — own ball, outright low net wins the hole` |
| sunningdale.test.mjs | 147 | internal-identifier | **leave** | `const at2 = html.indexOf('function sunnSoloEngine(');` |
| sunningdale.test.mjs | 149 | internal-identifier | **leave** | `  console.error('FAIL — sunnSoloEngine not found in index.html (solo engine not implemented)');` |
| sunningdale.test.mjs | 157 | internal-identifier | **leave** | `const sunnSoloEngine = new Function(`${html.slice(at2, end2)}; return sunnSoloEngine;`)();` |
| sunningdale.test.mjs | 159 | internal-identifier | **leave** | `const solo = (scoreRows, holes = 18) => sunnSoloEngine({ scores: scoreRows.map(r => S(...r)), holes });` |
| ci.yml | 5 | comment | **leave** | `# WHY: tests/preflight.mjs and tests/sunningdale.test.mjs already encode the` |
| ci.yml | 7 | comment | **leave** | `# misses, the stale dist allowlist, the 8-digit OTP trap, the Sunningdale` |
| ci.yml | 55 | comment | **leave** | `      # The Sunningdale engine contract (D74), extracted from index.html and` |
| ci.yml | 57 | internal-identifier | **leave** | `      - name: sunningdale engine` |
| ci.yml | 58 | internal-identifier | **leave** | `        run: node tests/sunningdale.test.mjs` |
| decision-log.md | 2297 | comment | **leave** | `### D74 · Sunningdale — the live game for groups without handicaps` |
| decision-log.md | 2302 | comment | **leave** | `- **Problem:** the pilot asked for Sunningdale (Golf Digest, 2026-07-21) — the` |
| decision-log.md | 2325 | comment | **leave** | `  widening live_rounds' game CHECK ('sunningdale'). 9-hole aware (D73:` |
| decision-log.md | 2341 | comment | **leave** | `- **Current:** four players picking Match Play or Sunningdale are silently a` |
| decision-log.md | 2351 | comment | **leave** | `  · **Sunningdale solo = deficit strokes vs the leader.** Own ball; a hole is` |
| decision-log.md | 2357 | comment | **leave** | `  · **⚑ OURS, flagged:** the article defines Sunningdale as strictly 2-sided.` |
| decision-log.md | 2364 | comment | **leave** | `  Solo Sunningdale's per-player bank liability is steep (3 payers) and is` |
| settings.json | 24 | internal-identifier | **leave** | `      "Bash(node tests/sunningdale.test.mjs)",` |
| index.ts | 30 | internal-identifier | **leave** | `  if (code <= 2) return { summary: "Mostly sunny", icon: "sun" };` |

---

## Outside the five surfaces

- **`sw.js`:69** — `e.waitUntil(self.registration.showNotification(d.title || 'Cup Season', {`
  This is the last string in the push pipeline and the only one the push-surface audit could not see — when the server payload has no title, the lock screen literally reads "Cup Season", which is a brand name, not a result.
- **`sw.js`:70** — `body: d.body || '',`
  A payload without a body ships a title-only notification, so a recipient can get a buzz whose entire content is the app's name — the opposite of "the result first."
- **`sw.js`:73** — `data: { url: d.url || '/' },`
  Every notification's destination defaults to the app root, so the tap that a result-carrying notification earns cannot land on the result; the push audit called for a deep link but this is the client half that would have to honor it.
- **`sw.js`:81** — `for (const c of list) { if ('focus' in c) return c.focus(); }`
  notificationclick focuses any already-open tab and never navigates, so even a correct deep link in `data.url` is silently discarded — the friend who taps "Jerecho beat his number" lands on whatever screen they left open.
- **`sw.js`:45** — `.catch(() => caches.match('/'))`
  There is no authored offline or update copy anywhere in the worker — a shared link opened offline falls back to the cached shell, or to the browser's own error page on a cold device, so the app's voice ends at the network boundary.
- **`index.html`:5180** — `ctr((d.name||'A GOLFER').toUpperCase(), 372, `600 44px ${MONO}`, INK, 7);`
  The round recap card bakes the full `display_name` into a 1080x1350 PNG — "JERECHO FISCHBECK" — where no first-name reducer applied to share text can ever reach it, and the fallback "A GOLFER" is a placeholder shipped to a group chat.
- **`index.html`:5195** — `ctr(theirs(bandName(Number(d.pvi))).toUpperCase(), 850, `600 46px ${MONO}`, GOLD, 9);`
  The card's hero line is a band label mechanically rewritten YOUR→THEIR and upcased ("BEAT THEIR NUMBER"), which is engine phrasing pushed through a find-and-replace rather than authored share copy.
- **`index.html`:5196** — `ctr(theirs(vsPhrase(Number(d.pvi))), 906, `500 31px ${SERIF}`, MUT);`
  Renders "beat their number by 4.2" into the image — the 4.2 is the differential wearing a friendly noun, and it is the single number a reader will try to interpret.
- **`index.html`:5198** — `if(d.badge) ctr('★ '+d.badge, 972, `600 31px ${MONO}`, GOLD, 5);`
  The milestone badge is baked into the shared PNG from the CARD_BADGE table, so it is outbound copy that no share-string grep surfaces.
- **`index.html`:5140** — `personal_best:'PERSONAL BEST', sub_80:'BROKE 80', sub_90:'BROKE 90',`
  CARD_BADGE is the string table for text rendered inside the shared image; every value here is an all-caps label a friend reads on a picture, never in the app.
- **`index.html`:5204** — `const when=`${DW[dt.getDay()]} · ${MO[dt.getMonth()]} ${dt.getDate()}`+(d.points!=null?` · ${d.points} PTS`:'');`
  "SUN · JUL 27 · 12 PTS" is a middot-joined data row baked into the artifact — the same run-on-with-dots grammar the owner rejected in the share text, now un-editable inside a PNG.
- **`index.html`:5201** — `ctr((d.course||'A ROUND').toUpperCase(), 1084, `600 36px ${MONO}`, INK, 4);`
  The course fallback "A ROUND" ships a placeholder noun as the artifact's location line whenever the round has no course label.
- **`index.html`:5207** — `ctr('cupseason.app', 1292, `500 27px ${MONO}`, MUT, 4);`
  The recap card's footer is a bare domain while the Major card's footer is a call to action — two artifacts from one brand end differently, and neither was in scope for the five surfaces.
- **`index.html`:5225** — `const file=new File([blob],'cup-season-recap.png',{type:'image/png'});`
  On any desktop or non-canShare path this filename is what the recipient sees as the attachment or download name, and it carries no result, no name, and no date.
- **`index.html`:10635** — `ctr('MAJOR CHAMPION', 348, `600 30px ${MONO}`, GOLD, 9);`
  Second baked-image surface (the jug card); its eyebrow, hero, and podium lines are all outbound text inside a PNG passed to navigator.share({files}).
- **`index.html`:10638** — `if(d.pvi!=null) ctr(mjVs(d.pvi)+' THEIR NUMBER', 850, `600 44px ${MONO}`, GOLD, 7);`
  Renders "4.2 UNDER THEIR NUMBER" — mjVs() is a private second phrase producer that disagrees with vsPhrase() used on the recap card, so the same concept reads two ways across two shared images.
- **`index.html`:10639** — `ctr('BEST CARD OF THE WINDOW', 906, `500 27px ${MONO}`, MUT, 5);`
  "the window" is internal Major-event vocabulary (the scoring period) printed on an artifact headed for people who have never opened the app.
- **`index.html`:10643** — `const pod=(d.podium||[]).map(p=>`${p.rank===2?'2ND':'3RD'} ${(p.name||'').toUpperCase()} ${mjVs(p.pvi)}`).join(' · ');`
  The podium line concatenates full legal names, upcased, joined by middots — the exact run-on shape the owner called unreadable, baked into an image.
- **`index.html`:10654** — `const text=`${d.name} takes ${d.jug} — ${d.gross}, ${mjVs(d.pvi).toLowerCase()} their number · cupseason.app`;`
  The Major card's caption travels with the image and duplicates what the picture already says, violating "the link carries the detail" at the image layer.
- **`index.ts`:41** — `const soft = (reason: string) => json({ unavailable: true, reason });`
  The scan function's whole failure vocabulary is machine slugs ("no_api_key", "disabled", "daily_cap", "monthly_cap", "scan_failed") and only one of the five is mapped to a sentence on the client.
- **`index.ts`:110** — `if (b64.length < 1000) return json({ error: "image required" }, 400);`
  These developer strings ("not signed in" :100, "bad request body" :106, "image required" :110, "image too large" :111) are the only words the function has for a hard failure, and nothing in the client maps them — they degrade to a generic catch-all toast.
- **`index.html`:5968** — `else toast('Scan’s resting — type your nines in');`
  One euphemism absorbs four distinct server outcomes (no key, global cap, model failure, network) plus every thrown exception at :5977, so the user is never told which — and "type your nines in" is house jargon for the front/back entry grid.
- **`index.html`:5967** — `if(data.reason==='daily_cap') toast('Scan limit for today — type your nines in');`
  The only reason slug that gets its own sentence; the copy exposes a cost-control cap as a user-facing rule without saying it resets.
- **`index.html`:5973** — `toast('Couldn’t read the card — type your nines in'); return;`
  Uses a curly apostrophe while humanError's parallel string at :3677 uses a straight one — the failure copy is not typographically one voice.
- **`index.html`:3673** — `else if(/jwt|not authenticated|auth session|invalid.*token|permission denied|row-level|not logged in/.test(m)) msg = 'Please sign in again.';`
  humanError's second rule catches `permission denied` and `row-level`, which is exactly what a signed-out friend hits on a share or claim link — they are told to sign in again when they have never signed in at all.
- **`index.html`:3678** — `else msg = 'Something went wrong — please try again.';`
  The terminal fallback in the only error-copy table in the app; it is what a recipient of a broken shared link most often reads, and it says nothing about what to do or who to tell.
- **`index.html`:3674** — `else if(/schema cache|does not exist|could not find the|no function matches|column .* does not/.test(m)) msg = 'Just updated — give it a second and try again.';`
  Deploy-skew copy written for the owner's own testing leaks a release detail ("just updated") to strangers who have no idea what updated.
- **`index.html`:3677** — `else if(/violates|constraint|not-null|null value|invalid input/.test(m)) msg = "That didn't go through — please try again.";`
  Straight apostrophe here versus curly apostrophes in the adjacent scan and epilogue strings — the same table mixes typographic conventions across strings that appear seconds apart.
- **`index.html`:15040** — `authStatus('Boot stalled at [' + bootStep + '] — network or auth hang', 'err');`
  Internal step names ('session','profile','memberships','bylaws','season-dates','enterLeague') print onto the sign-in door — the first screen a friend arriving from a shared link sees when the app is slow.
- **`index.html`:15095** — `authStatus('Boot failed at [' + bootStep + ']: ' + (e.message || e), 'err');`
  The one place humanError is bypassed entirely: raw Postgres/PostgREST text (e.g. "permission denied for table profiles") is concatenated onto the door status line, and the same call repeats at :15142.
- **`index.html`:12802** — `if(b){ b.style.display='block'; b.textContent='⚠ ' + msg + '  — screenshot this and send it'; }`
  The persistent error bar asks the user to screenshot and send a raw engine string — a directed outbound action whose payload is the least share-ready text in the app.
- **`index.html`:15418** — ``${data.guest_name || 'Your card'} — ${data.gross ? data.gross+' at ' : ''}${data.course_label || 'the course'}``
  This plus the continuation at :15419 is the very first Cup Season sentence a non-user ever reads after tapping a claim link from a friend, and it leads with a raw ISO date fragment and buries the ask behind three clauses.
- **`index.html`:15429** — `authStatus('That scorecard link has expired or was already claimed. Whoever sent it can share a fresh one from the round.', 'err');`
  The dead-claim-token message is what a recipient gets when the growth funnel fails — 121 characters, two sentences, and it pushes the recovery work back onto the sender.
- **`index.html`:15401** — `? `You're invited to ${pendName}. Enter your email and you'll join automatically.``
  The invite-link door copy (and its code-only variant at :15402) is recipient-facing landing text on the marketing door, not the /?share= page the landing audit covered.
- **`index.html`:15185** — `<div style="font-family:Georgia,serif;font-size:26px;margin:16px 0 8px">${ok?'You&rsquo;re unsubscribed':'That link has expired'}</div>`
  The D68 unsubscribe landing is a recipient-facing page, not an email, so the email audit did not reach it; "That link has expired" is also factually wrong for a token the RPC simply did not recognize.
- **`index.html`:15189** — `<a href="/" style="display:inline-block;padding:12px 20px;border-radius:11px;background:#FF5A2E;color:#1C1208;font-family:-apple-system,Segoe UI,sans-serif;font-weight:600;text-decoration:none;font-size:14px">Open Cup Se`
  The same dead app-root CTA the email audit flagged, repeated on the page the email links to — the recipient is bounced to a generic door with no context for why they arrived.
- **`index.html`:9234** — `tiles.push(cell(trophyIcon(t.kind), t.title||'—', (t.subtitle||t.kind||'')+yr, fresh(id)));`
  The trophy tile falls back to the raw DB `kind` slug ('league', 'ryder', 'major', 'bracket') as its visible subtitle, so a screenshot of the case can print a database enum under a trophy name.
- **`index.html`:9202** — `if(a.kind==='personal_best' && m.diff!=null) return 'Diff '+Number(m.diff).toFixed(1);`
  "Diff 8.4" prints the differential — the exact banned engine word — on a trophy-case tile, the surface most likely to be screenshotted and sent.
- **`index.html`:9237** — `box.innerHTML = '<div class="card" style="text-align:left"><div class="fine" style="padding:0">No hardware yet. Break 80, post your first round, or win a Cup Final — milestones and trophies land here.</div></div>';`
  The empty trophy case is what a new golfer screenshots or shows a friend, and this three-clause line buries the one achievable action (post your first round) in the middle.
- **`20260725190000_payout_penny_fixes.sql`:65** — `select lm.profile_id, 'league', lg_name, 'Points King', 'points_king', se.league_id, yr`
  The database engraves the title "Points King" while the client's career record at index.html:9271 calls the identical award a "Points crown" — one trophy, two names, both visible on screenshot surfaces.
- **`index.html`:7971** — `skipped.forEach(x=>rows.push(`<div class="check"><span class="num">—</span><div class="tt"><b>${esc(x.name)}</b><small>NOT POSTED · ${esc(String(x.reason||'')).toUpperCase()}</small></div></div>`));`
  Upcases raw SQL reason strings from finish_live_round ('no course rating', 'incomplete card', 'no index set', 'no 9-hole rating') into the post-round settlement sheet — the ceremony screen that sits directly above the Share button.
- **`index.html`:7973** — `rows.push(`<div class="check"><span class="num">🎟️</span><div class="tt"><b>${esc(g.name||'Guest')}</b><small>GUEST RECAP — SHARE THE LINK</small></div><button class="mini" data-copylink="${esc(url)}" style="flex:none">`
  "GUEST RECAP — SHARE THE LINK" is an instruction to the operator rendered in the same visual row family as the results, on the sheet a group crowds around after a round.
- **`index.html`:8054** — `toast(posted+' rounds posted & attested'+(guests.length?`; recap texted to ${guests.join(' & ')} with an app invite`:''));`
  Claims a text message was sent to named guests; nothing in the repo sends SMS — the actual mechanism is a copy-link button, so the app tells the host an outbound message went out that never did.
- **`index.html`:2721** — `<b>Guests need no account:</b> they play every side game, appear in the settlement, and get a recap text with their scorecard and an invite when you finish.`
  The same unbacked promise in the marketing copy of the play surface — "get a recap text" describes an outbound channel the product does not have.
- **`index.html`:5304** — `personal_best: { icon:'⭐', txt:'A personal best',                     sub:'The best round you’ve posted' },`
  The EPI_ACH table is the copy for the post-round epilogue sheet, the private ceremony that immediately precedes and feeds the Share button — its phrasing sets the expectation the shared card then fails to meet.
- **`index.html`:5354** — `rows.push(`<button class="btn" id="epiShare" style="width:100%;margin-top:14px">${firstEver?'Share your first card':'Share the card'}</button>`);`
  Three different share-affordance labels coexist across the app ('Share the card', 'Share a link — no account needed' at :5358, 'Share the settlement — no account needed' at :7976), so the user cannot tell which button produces an image and which produces a URL.
- **`index.html`:5281** — `toast('Link copied — no account needed to view it');`
  Post-share confirmation toasts are inconsistent across the four share paths ('Recap link copied' :7983, 'Card downloaded · caption copied' :5234 and :10662, 'Invite link copied: text it to the group' :11944) — the same act reports itself four ways.
- **`index.html`:5294** — `toast('Link is off — the page stops working for everyone');`
  Revocation copy that a sender reads right after having texted the link; it states the consequence but never names which link, so a user with several live shares cannot tell what they just killed.
- **`manifest.webmanifest`:4** — `"description": "Season-long fantasy golf with your own crew."`
  This string is surfaced by install prompts and OS app listings — an outbound description of the product that no audited surface owns, and it is the only place the product pitches itself in one line.

## Checked, does not exist

- A settlement image. The two navigator.share({files}) calls near index.html:5228 and :10656 are the ROUND recap card (drawRecapCard, index.html:5144) and the MAJOR champion jug card (drawMajorCard, index.html:10612). There is NO canvas or SVG artifact for a match-play, Wolf, or Skins settlement — the exact game the owner texted about ships as text plus a URL only (index.html:7986, csShareLink('settlement', ...)). The 'less words and more visuals' complaint has no image to fix; one has to be built.
- A season-recap shareable image. Sharing a season is a link only (index.html:14886, csShareLink('recap', CS.season.id, ...)); there is no season-end canvas artifact, no 'the season is over' ceremony screen, and no closeSeason/renderEndgame client renderer.
- Authored offline copy. sw.js has no offline page, no offline string, and no 'you're offline' branch — the navigate handler falls back to caches.match('/') (sw.js:45) and, on a device that never cached the shell, to the browser's own error page.
- Authored service-worker update copy. Nothing in sw.js or index.html tells a user a new version installed or asks them to reload; skipWaiting()/clients.claim() (sw.js:19, :27) swap the build silently.
- SMS/text sending. Despite index.html:8054 and :2721 both promising guests 'a recap text', there is no Twilio, no SMS provider, no sms: link, and no messaging code anywhere in the repo or in supabase/functions/. The only guest channel is a copied /?claim= URL.
- QA/analytics event names leaking to non-owner UI. qaEvent() (index.html:5460) writes slugs to client_events but nothing renders them to ordinary users; the only surface that prints raw event names is the founder desk (index.html:13264), which is gated in-body on auth.uid() = founder_id() (supabase/migrations/20260721191500_founder_desk.sql:4). Not a gap.
- A web share_target. manifest.webmanifest declares no share_target, so Cup Season cannot receive a shared scorecard photo from another app.
- A localization or copy string table. Every outbound string is inline at its call site; there is no i18n file, no copy constants module, and no single place any of these rewrites could be made once.
