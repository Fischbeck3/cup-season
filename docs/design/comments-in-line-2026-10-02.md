# Comments in line · a proposal for the owner's "build it" · 2026-10-02

**Owner, 2026-10-01 night:** "one thing we need to address before launch is comment interface,
current state if I click comment it takes me to a new page that gets cluttered and impersonal,
it also had an option to follow [a golfer] who I already follow. Comments must fall in line, be clear
to other users and me that i am making a comment on the round posted (encourages banter,
engagement etc...)"

**Status: BUILT as D405, awaiting verification and the owner's yes to ship** (2026-10-02, branch
`claude/comments-in-line-2026-10-02`, from `2b5004c4`). The owner approved the copy and the newest-comment
preview with its migration ("Copy approved, build the preview with the migration, build it"). The decision is
`spec/decision-log.md` D405; the server half is `20261224090000_comments_live_in_line.sql`; the API is the
D391 contract v1.5. Traced on the release source (`6727fd04`, the build attached to 1.0).

**What changed from this proposal while building** (each is in D405 or says why):
- **The ··· menu has ONE setting, "Notify me about"**: Every comment · Replies to me · Nothing. It replaces
  the proposal's "Mute conversation" + "Notify me about new comments". Replies to me needed a new thread
  state, `replies`, so a choice made on purpose is not undone by the next comment. The round's owner already
  hears every comment, so their menu offers two choices.
- **The composer reads "Comment on Theo's 84…"** (the proposal added "at North Grove"; the round is on the
  line above it, and long course names wrapped). On your own round: "Comment on your 79…".
- **Each comment row shows the face, the first name and how long ago** ("2h", the web's words), not a
  full name and a clock time.
- **The in-line list is flat and chronological** (a reply says "To Blake"); the round's page keeps replies nested.
- **The newest comment also shows under a round on the league board, on both clients**, not only on Home.
- **Notices name the round** ("Blake commented on Theo's round at North Grove.", "Blake replied to you on
  Theo's round.") and the dark comment push says the same.

**Found by four reviews of the build and fixed before it ships** (none changes what the owner approved):
- **An answer that began before a comment landed no longer takes it back out.** A Home or board read in flight
  when a comment was sent used to redraw the thread from its older snapshot (the comment gone, the door's count
  back). The web discards an answer that is no longer the newest for its thread; the phone draws only the newest
  read it asked for. The same holds for a Notify me about choice made while a read was out.
- **One draft per round, on both clients, wherever the thread is open.** The words, the comment being replied to
  and the key of a send not yet answered are shared by every view of the conversation (in line, the round's own
  page, the other tab). A reply target chosen on the page shows, and is sent, in line; a comment sent from one
  view clears the others and they read it; a second press of Send is the same comment, never a second one.
  The phone's door under the round follows whichever view read or sent last.
- **A refused send says so** even when its thread was redrawn while the comment was on the way (a Home read, a
  Reply pressed), folded, or out of sight (a sheet closed or opened over it, another view shown, scrolled away): on
  the web the line says it and the toast says it too where the golfer cannot see the line; on the phone the refusal is kept with the words it was
  refused for and is there when the thread opens again. The button stays off for the length of the send.
- **A doors read asked before a comment landed does not take the count, or the newest comment, back** (the web's
  doors, Home's and the board's on the phone): a thread's word about itself carries the time it was taken, and an
  older answer never overwrites a newer one. A thread whose FIRST read was still out when a comment landed from
  another view reads again instead of drawing the snapshot from before it.
- **The compact board's column** may be narrower than the newest-comment line (it ran off the side); **the full
  board** no longer jumps to the top under a quiet-day digest when a thread opens; **a thread on a board that is
  not showing** is not read on every refresh; **an open board thread on the phone** reads with its board.
- **An older server is not promised more than it does.** Before the migration a comment records no follow and
  the doors carry no newest comment: neither client says "Updates from this conversation are on" or draws a
  preview it cannot back, including a thread opened with no door of its own (a link, a notice), where the web
  goes by what its last doors read said.
- **A board holds more rounds than the doors' read takes (60):** both clients ask in batches, newest first, and a
  round the server leaves out of an answer loses its door.
- **Smaller:** the digest names a person on the phone as its other lines do; a sign-out (or a different account
  signing in) forgets drafts, from the root view, which outlives the screens that held them; the cursor
  an empty conversation opens with comes once, not on every reload; a failed doors read keeps an open Home thread's
  door so it can be folded.

Original status (kept for the record): PROPOSED, nothing built. Per the working protocol, code waited for "build it".

## What happens today

**On the phone** (the TestFlight build):
- **A Home round's "N comments" door opens the round's receipt as a full-height sheet**, titled
  "THE ROUND" and scrolled down to the conversation (`HomeView.swift:235-237`, `RoundReceiptSheet`
  with `focusComments`). On the way down: the moment card, points, photo actions, the course door,
  Share, the scorecard. Under the conversation: the receipt leaf. The conversation is one section
  of a long accounting page. That is the "new page that gets cluttered".
- **The page never says whose round it is.** No face, no name; the verdict is third person with no
  name (`ReceiptMoment.swift:76-115`, `RoundReceiptSheet.swift:125`). That is the "impersonal".
- **The composer says "Something for the crew…"**: nothing about the round or its golfer.
- **The "follow [a golfer]" button follows the conversation, not the golfer.**
  - The conversation's head row carries a bare **FOLLOW** button (`RoundConversation.swift:37-45`). It turns on a notice for every new comment on *this round*.
  - N4-202 (`587e53ed`, 2026-09-29) moved it out of the ··· menu, where it read "Follow conversation", into a visible button reading just "Follow". It is set in the capitals used for people's names, on a page that never names the golfer, so it reads as following the golfer.
  - The setting is per round, and commenting doesn't turn it on. So every new round from someone you already follow shows FOLLOW again.
  - The product has no person-follow anywhere: buddies are `friendships`, and D25 says "no follows".
- On the **league board** the thread already opens in line under the post.

**On the web:** the same pattern.
- The Home card's comment count is a door to the receipt sheet, and the conversation sits *below* the receipt there.
- The same "Follow"/"Following" button, and the same placeholder.

**Data:** D391 already keeps **one thread per posted round**, merged on the server (`posted_round_thread`,
`add_posted_round_comment`). Nothing about the data needs to change for comments to appear in line.

## The proposal (recommended)

1. **The thread opens in place, under the round.**
   - On Home (both clients) and the league board, the round's comment door expands the conversation directly beneath the card. No new page and no sheet; the round stays on screen above it.
   - The newest three comments show, with "Earlier comments (N)" above them. The composer sits at the foot, and the keyboard rises with it.
   - A posted comment appears in line at once. The same door collapses the thread.
2. **A round with comments shows the newest one under the card, before any tap**, e.g. "Blake: Did the putt on 18 drop?" with "3 comments". This is what makes banter visible; a count alone hides it. It needs one new field on `posted_rounds_social`: one migration, and the clients fall back to the count if it is missing.
3. **Every comment says what it is on.**
   - The composer reads **"Comment on Theo's 84 at North Grove…"**; on your own round, **"Reply to the crew about your 79…"**.
   - Each comment row shows the face, the first name and the time; a reply reads "to Blake".
   - The round's own page names the golfer: **"THEO'S ROUND"** with their face ("YOUR ROUND" stays). Its conversation head reads "On Theo's 84".
   - All of this is one shared copy producer, used by both clients.
4. **The bare "Follow" goes.**
   - Commenting on a round turns its notices on for you, so banter comes back to you.
   - The ··· menu keeps "Mute conversation" and gains "Notify me about new comments" / "Notifications on".
   - No control reads "Follow" anywhere (D25).
5. **Push for comments stays your separate call.** In-app notices exist; push is dark behind `app_flags.social_comment_push`. Turning it on is a production setting and needs its own yes, after the phone checks.

**Also fixed in the same pass** (found while tracing):
- The person page offers "Add buddy" to an existing buddy whenever the buddy list fails to load. The failure is swallowed (`TourCard.swift:477-481`, `PersonPage.swift:271-273`).
- Home's "commented" digest never counts round-thread comments, because it reads only legacy board comments (`HomeSocial.swift:205`).

**Considered and not recommended:**
- **A half-height comments-only sheet with the round pinned on top.** Less work, but it is still a separate surface, which is the complaint.
- **Threads always expanded on Home.** Home becomes a wall of comments: D28(c)'s density concern, rightly.

## What it costs and what it moves

- **Work.**
  - Phone: an in-line thread under the Home card and the board post (reusing `RoundConversation` in a compact form), the composer and title producers, and the follow change.
  - Web: the same in `index.html` in its desk shape.
  - The migration (newest-comment preview, plus auto-follow on comment if done on the server).
  - Tests on both clients.
  - Roughly a day of build and verification.
- **Launch.**
  - Submission waits for it. Build 2097 (attached now, not submitted) is replaced by the next build. The web and the database each deploy once more, each on your yes.
  - The App Store frame 5 (the receipt) shows the bottom of the conversation's composer and must be re-checked after the change. No other frame shows comments.

## The decision entry (to be numbered when built; drafted in the log's format)

**Comments live in line under the round they are on, and say whose round it is.**
- **Current state.**
  - D391 keeps one thread per posted round. Its contract makes the round's receipt the conversation's only place, and Home, the board and the inbox only doors to it.
  - The phone opens that receipt as a full-height sheet that never names the golfer, under a bare "Follow" that follows the conversation.
- **Problem.**
  - The owner's own first use: a new page, cluttered and impersonal, and a "follow" for a golfer the owner already follows.
  - Banter needs the conversation where the round is read, and it needs to say whose round it is.
- **Recommendation.** Items 1–4 above. Item 5 stays a separate production decision.
- **Principle served.** The app should feel alive (vision). The round is the object the conversation hangs on (D391's IA, kept). One fact, one place: still one thread, now shown where the round is.
- **Benefit.** A comment is one tap from the round, where everyone reads it. It says whose round it is on, and the person who comments hears the replies.
- **Tradeoffs.**
  - Home grows by one line under any round with comments, and by the thread while it is open.
  - Applause stays per board post while comments are per round (D365/D391, unchanged).
  - One migration.
- **CONFLICT.**
  - The D391 contract's placement rule ("the Home wire, the board and the inbox are DOORS to it, never second copies of it") is superseded at the UI level. The data rule (one thread per round) stands.
  - D28(c) ("comments stay a board-only thing") was already superseded by D391 and IOS-076.
  - D25's "no follows" is honoured better than today.
