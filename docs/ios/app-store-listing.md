# App Store listing — paste-ready (IOS-027)

Companion to `docs/ios/app-review-notes.md` (the Review Notes field — already
written, not repeated here) and `spec/appstore-launch-kit.md` (the source of
every paragraph reused below). Character limits: name 30 · subtitle 30 ·
promotional text 170 · description 4,000 · keywords 100. Name + subtitle +
keywords are the only search-indexed fields.

The posture rule holds over every field: store copy is legal copy. The D39
canon appears verbatim; bet / betting / gambling / wager / odds / action /
units / "takes no cut" / "never held" appear nowhere, keywords included. The
Founding League offer appears nowhere in the listing (outreach only).

---

## 1. Name, subtitle, category

**Name (10/30):**
> Cup Season

**Subtitle — recommended (20/30):**
> Run your golf season

Two alternates, either pastes as-is:
> Golf leagues, handicaps, skins  *(30/30 — keyword density)*
> Seasons, handicaps & skins  *(26/30 — the kit's alternate)*

*Why the brand line (runbook D2, re-decided for the shorter name):* the
runbook's case against it was that "golf" repeated a word already in the
name and so indexed nothing. The name is now `Cup Season`, ten characters
with no "golf" in it — the brand line is the only place the word appears, so
it now carries the one search term that matters AND says what the app does
in the user's own vocabulary. Discovery is not the channel (the funnel is a
claim link from a friend, foursome by foursome), and the subtitle is editable
without review; if organic search ever matters, swap to the 30-character
alternate then.

**Category:** Sports. **Secondary:** Lifestyle.

## 2. Promotional text (147/170 — editable any time, no review)

> Season three of the founding league is under way. Draft the crew, post real
> rounds, and race a season-long cup with standings that show their work.

## 3. Description (2,576/4,000)

> **Retire the spreadsheet. Run your golf season in your pocket.**
>
> Cup Season is the operating system for your crew's golf season. Captains
> draft squads, everyone posts real rounds from any course, points pile up
> month after month, and the season ends the way a season should: with a Cup.
>
> **How a season works.** The Pro sets the bylaws once — squads or solo, the
> handicap allowance, how many rounds count a month, the endgame — and locks
> them at first tee. From there the season runs itself. Every posted round
> scores against your number, the best ones count toward the month, and the
> standings tell the story as it happens: who leads, who is climbing, who is
> one good weekend from the top. It ends with a four-week Cup Final or the
> points table, settled by a tiebreak ladder that never needs a committee.
>
> **Post a round in under a minute.** Pick the course, type the front and back
> nines, or enter your card hole by hole. Photograph a paper scorecard and
> the app reads it for you. Your number comes from the scores you actually
> post — no self-reported vanity handicaps. Round cards speak plainly ("beat
> your number by 3"), and every standings figure taps through to the exact
> rounds that produced it. Receipts, always. The handicap argument is over.
>
> **The live round.** Put your group on the tee sheet and score Match Play,
> Wolf, or Skins hole by hole, on one phone or four. Strokes come off
> automatically, the ladder updates as you walk, and the settlement card at
> the end says who won what. Played a guest? One link makes their round
> theirs for good.
>
> **The Ryder.** Run a cup weekend or a rivalry across leagues: rosters,
> sessions that open and close on their own, a number to beat for every duel,
> a scoreboard, and an MVP when the dust settles.
>
> **The record.** Rivalries with names, trophies that stay in the case,
> month-close stories, a board where the crew talks, and a season recap worth
> sharing. A golf life that adds up instead of evaporating into a group chat.
>
> **What it costs, plainly.** Nothing. Every golfer's profile, index and
> record, and every league, event and round — all free. Nothing is sold in
> this app or anywhere else, there is no trial, and there are no in-app
> purchases.
>
> **The money, plainly:** Cup Season keeps the ledger; the money moves between
> friends — not through the app. No wagering, no deposits, no payouts. Just
> every dollar of your crew's pot on the books, where the whole league can see
> it. A league can also run on bragging rights alone.
>
> Grab your crew. Draft the squads. Post the rounds.
> **Where amateur golf counts.**

## 4. Keywords (98/100)

> handicap,skins,match,play,wolf,scorecard,standings,draft,league,buddies,friends,fantasy,trip,ryder

No spaces after commas. No repeat of a name word (cup, season) or a subtitle
word (run, your, golf). "league" earns its place now that the name no longer
carries "Golf Leagues"; "ryder" is the one term a golfer types that no
competitor field says. Nothing in the banned list.

## 5. URLs and copyright

| Field | Value | Note |
|---|---|---|
| Support URL | `https://cupseason.app` | **Flag:** there is no `/support` page. The repo serves `index.html` and `legal.html` only, and `netlify.toml` has no `/support` redirect. Either add a one-line redirect `/support → /legal.html` (then paste `https://cupseason.app/support`) or leave the root, which resolves. App Review requires the URL to load; both do. |
| Marketing URL | `https://cupseason.app` | optional field |
| Privacy Policy URL | `https://cupseason.app/legal.html#privacy` | the anchor `legal.html` §Privacy Policy; the same link the sign-in screen and Settings use |
| Copyright | `2026 Jerecho Fischbeck` | **Flag:** no legal entity is named anywhere in the repo (`legal.html` says "CupSeason", the contact is a personal address). If an LLC exists, its name goes here instead. Apple's format is year then owner, no © needed. |
| Support contact (App Review "Contact Information") | Jerecho Fischbeck · jerecho@fischbeck3.com | the launch kit's press contact; `legal.html` lists `jerecho@fischbeck3.com` — pick one and make the two agree |

## 6. Age rating — REWRITTEN 2026-09-01, because the questionnaire below was retired

**The table that stood here answered a form Apple no longer serves.** It was
written against the pre-2025 questionnaire (Cartoon Violence / Horror Themes /
Simulated Gambling, and a single 4+ / 9+ / 12+ / 17+ ladder). Apple replaced
that in **July 2025** with a different set of questions and a five-tier ladder:
**4+ / 9+ / 13+ / 16+ / 18+**. Answering the old questions from memory in front
of the new form is how a wrong rating gets submitted, so the old table is gone
rather than left to be copied.

**Do not fill this in from this document.** Read each question off the live
form in App Store Connect and answer it. What follows is the reasoning to bring
with you, not a transcript of the form.

### The two answers that actually decide the rating

**Contests — answer honestly, and expect 13+.** The current questionnaire asks
about content where users compete for rankings, rewards or personal goals.
Cup Season is a season-long competition with a standings table, a Cup Final and
a champion; that is the entire product. The instinct is to answer "None"
because the old form's nearest neighbour was Simulated Gambling — but these are
different questions, and this one is plainly yes.

**13+ costs nothing commercially** and buys two things worth having: it is the
truthful answer, and it moves the app out of the tier where Apple's child-audience
scrutiny (and the COPPA-adjacent expectations that ride with it) apply to a
product that has **no age gate anywhere in its schema** — no date of birth, no
attestation, nothing. Claiming 4+ for an app with a chat board, real money owed
between adults and no age gate is the kind of answer that gets noticed later,
in a worse conversation than this one.

**Gambling — answer No, and know exactly why.** The question is about betting
or wagering with real money. Cup Season has no payment rail of any kind: no
Stripe, no escrow, no Venmo/PayPal/Zelle, nothing. Verified in the audit of
2026-08-31, twice, independently: the only "stripe" in the client is a CSS
colour. The pot is a **ledger of a friend group's own arrangement**, settled
between them outside the app, exactly like a shared spreadsheet — the Guideline
5.3.4 paragraph in the Review Notes says this and is the thing to point at.

Two facts that make that answer defensible rather than merely asserted, both
true as of 2026-09-01:

- The per-round stake field is **capped at $200** and clamped server-side of
  the input, matching the season buy-in ladder's own ceiling (D192). It was
  unbounded, which was the one surface where "this is a ledger, not a book"
  stopped being obvious.
- The words **"paid from the pot"** are out of the binary (D187). They were
  behind a flag that is off, one row-update from rendering, and they were the
  sentence that would have made Cup Season a beneficiary of the stakes.

### Everything else

None / No, and all of it is true of the binary: no violence of any kind, no
profanity, no mature or suggestive themes, no horror, no medical content, no
alcohol/tobacco/drugs, no sexual content, no loot boxes or randomised
purchases, no advertising, and no unrestricted web access — the app opens no
browser, and the only outbound links are Terms and Privacy.

**User-generated content / messaging** is **Yes**: the board is chat between
members of a private league. This does not raise the rating on its own, and
the app now satisfies all three things Apple looks for alongside that answer —
report, block, and the developer able to act (D188). The Review Notes' 1.2
section lists each one and where to find it.

## 7. App Privacy (nutrition label) — matches `apps/ios/CupSeason/PrivacyInfo.xcprivacy` exactly

**Do you or your third-party partners collect data from this app?** Yes.
**Tracking:** **No** — `NSPrivacyTracking = false`, no tracking domains. No ad
SDK, no broker, no cross-app identifier; answering yes would demand an ATT
prompt for nothing (runbook D9).

Seven data types, one row per manifest entry. Every one is **Linked to the
user's identity** and **not used for tracking**.

| ASC category → data type | Manifest key | Purpose(s) | Linked | Tracking | What it is |
|---|---|---|---|---|---|
| Contact Info → Email Address | `EmailAddress` | App Functionality | Yes | No | the sign-in address (email one-time code); `profiles.email` |
| Contact Info → Name | `Name` | App Functionality | Yes | No | the golfer's display name on the card, the board and the standings |
| User Content → Photos or Videos | `PhotosorVideos` | App Functionality | Yes | No | round photos, the card photo, the scorecard scan (private `media` bucket) |
| User Content → Other User Content | `OtherUserContent` | App Functionality | Yes | No | rounds, board posts and chat, league settings |
| Identifiers → Device ID | `DeviceID` | App Functionality | Yes | No | the APNs push token (`device_tokens`) — push only |
| Diagnostics → Crash Data | `CrashData` | App Functionality | Yes | No | MetricKit crash and hang reports into `client_events` (IOS-024) |
| Usage Data → Product Interaction | `ProductInteraction` | **Analytics** | Yes | No | screens opened and taps (`client_events`, `pilot_instrumentation`) |

Not collected, and do not tick: Location (course search is by name, never by
GPS), Health & Fitness, Financial Info (the pot is a ledger of dollars typed
by the Pro; no payment instrument exists), Contacts, Browsing/Search History,
Purchases, Sensitive Info. Course lookups go through our own Edge Function
with the key held server-side — the third party never sees a user, so it is
not a disclosure.

Keep this table, `PrivacyInfo.xcprivacy` and `legal.html` §Privacy in
agreement; when one changes, the other two change in the same commit.

## 8. What's New — 1.0 (community voice, never changelog-speak)

> The clubhouse door opens. Seasons, drafts, real-round handicaps, Match
> Play, Wolf and Skins with settlement cards, Ryder-style events, trophies,
> and standings that show their work. Founding league: PIGL, Tempe, AZ.

## 9. Field-by-field paste order in App Store Connect

1. App Information: name, subtitle, category (§1), privacy policy URL (§5),
   age rating (§6).
2. App Privacy: §7, then publish.
3. Version 1.0: promotional text (§2), description (§3), keywords (§4),
   support + marketing URLs (§5), copyright (§5), What's New (§8),
   screenshots (launch kit §3), Review Notes + reviewer sign-in
   (`docs/ios/app-review-notes.md`).
