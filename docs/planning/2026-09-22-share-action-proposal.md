# W2 · One Share action from a posted round — the concrete flow, and the entry to rule on

**2026-09-22, remote session on `claude/october-launch`.** The launch plan's
W2 (§3) needs one product decision before it is built; rule 5 says the
decision-log entry comes first. This is that entry, drafted in the
hierarchy-of-truth format with the one question the owner has to answer. The
photo-consent half is not in question and is built first whatever the answer
(§4 below). Nothing here is built yet.

## 1 · What exists today, read from the code

**The desk, from a posted round.** Three doors on two surfaces:

| Door | Where | What it produces | Photo |
|---|---|---|---|
| *Share a link* (`csShareLink('round', …)`, `index.html:9570`) | the finish ceremony / epilogue | `create_share` mints (or re-returns) the live token → `/?share=TOKEN`; the share sheet gets title + text + url | if the round has a photo, a 1600px copy is uploaded to the public bucket at `shared/{token}.jpg` **unasked**; the button reads *Share a link — card + photo* (D60: disclosure before the tap, but no way to say no) |
| *Share the card* (`shareRoundCard`, `:9359`) | the round receipt (the golfer's own round only) | a PNG of the round card via `navigator.share({files})` or a download; **no link** | the card artifact draws what the receipt shows |
| *Revoke the link* (`csRevokeLink`) | the epilogue | `revoke_share`; the copy is deleted on revoke | — |

The recap card, the settlement card (+ its own link, with the PNG published at
mint so the link's preview is the card — D78) and the Major card are separate
artifacts on their own surfaces and stay so.

**The phone.** `PostService.shareLink(round:compress:)` mints the token and,
when `rounds.photo_path` is set, uploads the compressed copy to
`shared/{token}.jpg` on its own — no question asked; the link ships
photo-less only when a step fails. `ShareIntent` / `ShareLinkService` carry the
person and plan links (D241/D253), not the round.

**The public page and the preview.** `/?share=TOKEN` (`renderShareView`) draws
`shared/{token}.jpg` as the card's ground when `share_info.photo` is true;
`netlify/edge-functions/share-preview.ts` sets `og:image` to the same copy.
`share_info.photo` is `exists(copy)` — the storage object, not a consent flag.
`create_share` re-returns the one live token per (kind, ref, sharer), so a copy
uploaded once serves the page and the preview for as long as the token lives.
The storage policy lets the sharer delete their own token's copy at any time.

**Growth.** `csShareLink` logs `artifact_shared` (kind `share`); the phone's
`ShareLinkService.mint` logs the same for person/plan; `log_growth_event`
records `link_opened` on the public page. `v_growth_funnel` reads them and has
no reader yet (W6).

## 2 · The proposed entry — D380 (IA + UI level), for the owner to rule

**Current mechanic.** Above: two doors on the desk for one round (a link with a
photo that travels unasked; a card with no link), one door on the phone (a link,
photo unasked), and a public page whose preview is the brand image unless a
photo travelled. A golfer who wants to send "my round" has to pick a door and
cannot decline the photo.

**Problem.** The loop is *play → understand → share → bring a friend*, and the
share step has no single act that produces the thing a friend will open. The
consent gap is a privacy defect on its own: a golfer who attached a photo to
their round for their leagues has not thereby agreed to publish it to anyone
holding a link, and once published on a reused token it stays published.

**Recommendation (to rule).** **One `Share` action from a posted round, on both
clients, that produces the round card and the contextual link together** — the
share sheet carries the card image and the `/?share=TOKEN` url in one payload
(`navigator.share({files, text, url})` on the web; `ShareLink` with both items
on the phone), and the card PNG is published at mint to `shared/{token}.png`
exactly as the settlement card already is (D78), so the link's preview *is* the
card wherever the message lands. The recap, settlement and Major artifacts stay
where they are. The card is drawn by the existing producer
(`drawRoundCardArtifact` / the phone's twin) in the established visual system
— nothing new is designed.

**Photo consent, whatever the shape.** When the round has a photo, the action
asks once, on the share step, *Include your photo* — on by default because the
golfer attached it to this round, and one tap to off. The answer governs all
three outputs: the exported card image (drawn with or without the photo), the
public page (the copy exists or it does not) and the preview (`og:image` is the
card PNG; the photo is in it or not). **No** means no copy is uploaded and, on a
reused token that already holds a copy, the copy is deleted before the share;
because a preview cache may hold the old image, the token is revoked and
re-minted in that case so the old url cannot keep serving it. Never another
golfer's photo; the marker medallion stays (D59). Findability (`discoverable`)
and revocation are untouched: a golfer whose findability is *nobody* is never on
a card they did not share themselves, and revoke still kills the token and the
copies.

**Principle served.** Principle 2 (low friction: one act); §16's honesty about
what leaves the app; D297 (one producer per client, the same words); D60's own
sentence — *the tap is the publish act* — made true by giving the tap a no.

**Benefit.** The friend opens a message that already looks like the round; the
public page and the preview never show a photo the golfer did not say yes to; a
withdrawn yes cannot be served from a cache.

**Tradeoffs.** One more question on the share step when a photo exists; a
revoke-and-re-mint changes the url for a golfer who un-includes a photo (the old
link dies — the honest outcome). The phone's `shareLink` gains a consent
parameter and a card render; the desk's two doors become one. About two working
days for both halves plus the consent tests.

**CONFLICT.** None named. D60 ("the photo travels") is amended, not
contradicted: it travels when the golfer says so.

**Files.** Web: `csShareLink` (`index.html:9570`), `shareRoundCard` (`:9359`),
the epilogue's `#epiLink` / `#epiShare` (`:9972`), `renderShareView`
(`:30760+`), `netlify/edge-functions/share-preview.ts` (`metaFor`, the round
branch). Phone: `PostService.shareLink`, the receipt's share control
(`RoundReceiptSheet`), a card producer twin. Server: **none** — `share_info`'s
`photo: exists(copy)` and the storage policies already carry the design; no
migration, no anon-surface change (the twelve stay twelve).

## 3 · The one question for the owner — **ruled 2026-09-22: A.** Logged as D380 in `spec/decision-log.md`; built the same day on both clients.

**The shape of the one action.** (A, recommended) the card image *and* the link
in the same share sheet, with the card PNG published at mint as the link's
preview; or (B) the link alone, with the card PNG published at mint as its
preview, and the card image reachable only through the link. A puts the picture
in the message itself (iMessage renders both); B keeps the message to a link.
Everything else in §2 is the same under either.

## 4 · Built first, under either answer — the consent half

The acceptance rows from the launch plan §3 that do not depend on the shape:

- On both clients, declining the photo keeps it out of the exported image, the
  public page and the preview, **including when the token already existed with
  a copy** — proven by reading `share_info` for that token (`photo: false`) and
  fetching the copy's url (404).
- Accepting puts it in all three.
- A round without a photo shares the card without one and asks nothing.
- A Kit test on `shareLink` with consent false and a copy present; a web pin on
  the consent branch in `tests/app-tests.js`.
- The share appears in `v_growth_funnel` (`artifact_shared` / `link_opened`).

Order of work once ruled: the consent half on the web (`csShareLink` gains
`includePhoto`, the delete-then-revoke-re-mint branch, the toggle on the
epilogue) → the same on the phone (`shareLink(round:includePhoto:compress:)`)
→ the one action's web half → its phone half on the Mon 28 build.
