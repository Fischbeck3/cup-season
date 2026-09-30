# SPLIT-PLAN — index.html's scripts into their own cached files (Q12 part 2)

**Ruling (owner, 2026-09-29):** "Split, keep comments." Before launch, if it is proven by the freeze;
otherwise root ships without it and it takes the first push after launch.
**Built by:** agent S, branch `claude/ten-s-split-tooling-2026-09-29`, on integration `e033161d`.
**What this branch carries:**
- this plan;
- `tools/split-scripts.mjs`: the transformation `split`, the asserted edits `wire`, the inverse
  `join` / `readAppSource`, and the guards `check`;
- `tools/split-scripts-measure.mjs`: the before/after measurement.

It does NOT split this branch's `index.html`. Root runs the tool once, at the very end, on the final
merged tree.

---

## 1 · What moves

`index.html` at `e033161d` is 2,454,571 bytes with four script blocks (CLAUDE.md: three classic, one module).

| # | block | where | bytes | after the split |
|---|---|---|---|---|
| 0 | pre-paint theme (`applyTheme`, `cs-returning`) | end of `<head>` | ~2 KB | **stays inline**. It must run before first paint. |
| 1 | `#errbar` handlers + SW registration | right after `<div id="errbar">` | ~3 KB | **stays inline**. It reports everything below it, and the SW update path must not depend on a file loading. |
| 2 | the classic UI block (demo data, renderers, the boot render chain) | body | 1,326,713 | `app/classic.js` |
| 3 | the `type="module"` backend (supabase-js, auth, data layer, `bootStep`, the 8 s watchdog, `window.*` bridges) | end of body | 568,182 | `app/module.js` |

`index.html` drops to 560,314 bytes: the CSS, the markup, blocks 0–1 and the bridge below. Each moved
block is replaced **in place** by exactly one tag:

```html
<script src="/app/classic.js?v=__CS_VERSION__"></script>
<script>/* the Supabase bridge (R13), ~12 lines */</script>
<script type="module" src="/app/module.js?v=__CS_VERSION__"></script>
```

The bytes between the old tags are written to the files unchanged, with one deliberate exception. **Comments
stay**: nothing is stripped, minified or re-encoded.

**The exception (R13, root's ruling 2026-09-29).** `netlify/edge-functions/share-preview.ts` parses the
project URL and the publishable key out of the origin HTML with `/const SUPABASE_URL\s*=\s*'([^']+)'/` (and
the `_KEY` twin). Both lines sat in the module block. `split` therefore moves those two lines, verbatim,
into a tiny inline classic script placed right before the module tag:
- the two `const` lines sit inside an IIFE, so no global lexical binding is added;
- the script sets `window.CS_SUPABASE_URL` and `window.CS_SUPABASE_KEY`, an explicit bridge per
  CLAUDE.md's `window.*` rule.

In `app/module.js` the two lines become `const SUPABASE_URL = window.CS_SUPABASE_URL;` (and `_KEY`). Two
lines replace two, so the module's line numbering is unchanged. `join` folds the bridge back, so every
static reader still sees the original module lines.

There is no Netlify env dependency and no edge-function change. The key is edited in exactly one place:
the bridge's two const lines.

## 2 · Options considered

**(a) Split in source; every static reader reads the joined file.** The repo holds `index.html` +
`app/classic.js` + `app/module.js`. One reader, `readAppSource(root)` in `tools/split-scripts.mjs`, gives
preflight and the suites the pre-split `index.html` back, byte for byte. The browser harness and the suites
serve the root as it is, so they load the real files.

**(b) Split at build.** The source stays one file; `stamp-version.sh` splits the `dist/` copy; the harness
and suites would run against a built `dist/`.

**Sub-options, rejected:**
- Stripping comments at build (AW2-12's other half). The ruling says "keep comments".
- `defer` on the classic script. That would move the classic boot chain after parsing, into the deferred
  queue. The chain would then run behind the rest of the markup rather than where the parser meets it.
  The Door's `cs-returning` hold, its 3 s floor and the "classic chain before the module" rule would come
  to rest on tag order inside that queue. It changes boot timing for no gain the split needs, so it is not
  done (and `check` fails on it).
- Moving blocks 0 and 1 too. Block 0 must beat first paint. Block 1 is the error reporter and the SW
  registration. Together they are ~5 KB, so moving them gains nothing.
- One combined file. The classic ↔ module boundary is a scope boundary (CLAUDE.md's landmine), and the
  module needs `type="module"`, so two files are the minimum.

### Chosen: (a). Why

1. **What ships is what is tested.** CLAUDE.md's verify discipline serves the SOURCE
   (`python -m http.server`), and so does the capture harness (`--serve http` on the root). Under (b),
   every local check, every harness run and every browser suite would test the one-file app, while
   production ran the split one. The split's real risks (script order, the SW cache, MIME types, the
   stamp) would first appear in production. Under (a) they appear on every local run.
2. **The deploy path gains no transform.** Netlify's build stays `bash ./stamp-version.sh`: `cp` plus
   `sed`, with one more directory copied and two more files in the existing stamp loop. There is no parser,
   no Node step and no new dependency. Under (b) the build would carry a rewriting step, which is exactly
   what "no JS parser in the deploy path" guards against: a split that exits 0 but ships broken output is
   not caught by Netlify keeping the previous deploy. That fallback only covers a build that fails.
3. **The tests keep every script's source, provably.** `readAppSource` is the exact inverse of the split.
   `check` proves `split(join(tree)) === tree` on every preflight run, so a reader sees the same bytes, with
   the same line numbers, that it reads today.
4. **The cost of (a) is the merge.** After the split lands, a branch that still edits `index.html`'s
   scripts will not merge textually. That is why root applies it last, and §6 gives the recipe for a late
   hunk.

## 3 · Boot semantics: why the order is unchanged

- **The classic block.** An external classic script without `defer`/`async` blocks the parser at exactly
  the spot where the inline block stood. It runs to completion before the parser reaches anything after
  it. Top-level `function`/`var` declarations still become `window` properties (it is the same Script goal
  in the same global), so the classic-side names and the `window.*` bridges are unchanged.
- **The module block.** A module script is deferred whether it is inline or external. It runs after
  parsing, before `DOMContentLoaded`, and so after the whole classic chain, as today. `import.meta`,
  `document.currentScript`, `document.scripts` and relative `import()` appear nowhere in `index.html`
  (grep at `e033161d`), so moving the module's URL changes nothing it resolves. Its only import is the
  absolute, pinned esm.sh URL.
- **The bridge runs between the two.** It is a classic inline script after the classic tag and before the
  module tag. It runs synchronously once the classic chain has finished, and it only sets two `window`
  properties. The deferred module reads them at its top. Nothing in the classic block names `SUPABASE_*`
  or `CS_SUPABASE_*` (grep at `e033161d`).
- **Blocks 0 and 1 stay inline, in place.** The pre-paint theme, `#errbar`, the `error` /
  `unhandledrejection` handlers and the SW registration run exactly when they do today. `bootStep`, the
  8 s watchdog and `bootResolved` live inside the module file, unchanged.
- **Encoding.** The page is UTF-8 (`<meta charset>`). A classic script served without a charset decodes
  with the document's encoding, and a module script is always decoded as UTF-8. The mixed middot forms
  (the `·` escape and the real `·`) therefore reach the engine as they do today.
- **MIME.** Both files are `.js`, never `.mjs`, so the local server, the harness (`MIME['.js']`) and
  Netlify all serve a JavaScript type. `nosniff` plus a module script with the wrong type is a hard failure.
- **Proven, not argued:** see §7. The harness captures are pixel-identical, the bridges are present at
  the end of the boot, and `bootStep` reaches `reveal` in both trees.

## 4 · Every file it touches (tomorrow's apply)

Written by `node tools/split-scripts.mjs split` (the tool refuses any other shape):
- `index.html`: the two tags replace blocks 2 and 3. Blocks 0 and 1, the CSS and the markup are
  untouched. None of the four `__CS_VERSION__` sites is edited:
  - the Door's caption and the desk sidebar's build identity stay in `index.html`, which now holds four
    placeholders (those two plus the two `?v=` tags);
  - the settings foot's line and its comment move, byte for byte, into `app/module.js`, which holds two.
- `app/classic.js`, `app/module.js`: new, byte-exact block bodies. The one exception is the module's two
  Supabase const lines, which move to the inline bridge and are replaced by `window.CS_SUPABASE_*` reads.

Written by `node tools/split-scripts.mjs wire`. Every anchor is asserted: a moved anchor, or a file
that is already wired, refuses and writes nothing, naming the file. All of it is proven on the scratch copy:
- `stamp-version.sh`
  - after `cp -r brand "$DIST/brand"`, add `cp -r app "$DIST/app"`;
  - the sed loop: `for file in "$DIST/index.html" "$DIST/sw.js" "$DIST/app/classic.js" "$DIST/app/module.js"; do`;
  - the survival grep: the same four files;
  - the non-empty loop: add `app/classic.js app/module.js`.
  The `?v=` query rides the existing `index.html` stamp. `app/module.js` carries the settings foot's
  `v23 · __CS_VERSION__`, so the stamp follows it there.
- `sw.js`: two SHELL entries after `'/'`: `'/app/classic.js?v=' + VERSION,` and
  `'/app/module.js?v=' + VERSION,`. The **VERSION line is untouched**; the entries reuse the constant.
- `tests/preflight.mjs`
  - import `readAppSource` and `check as splitCheck` from `../tools/split-scripts.mjs`;
  - `const html = readAppSource(root)`;
  - new check 1b, "split layout", which runs `splitCheck(root)`;
  - check 4: strip the `?v=` query and accept anything under a `cp -r <dir>`;
  - checks 21 and 21b: add `app/classic.js` and `app/module.js` to their file lists.
- `readFileSync(… 'index.html' …)` becomes `readAppSource(root)` in:
  - `tests/attribution-trace.test.mjs`, `homefold.test.mjs`, `post-request.test.mjs`, `rating.test.mjs`,
    `sunningdale.test.mjs`, `trophycase.test.mjs`, `season-book.test.mjs`, `share-consent-flow.test.mjs`,
    `ten-lock-probe.mjs`;
  - `tools/build-markers.mjs`, `tools/extract-strings.mjs`.
- `package.json`'s description: "a single static index.html" becomes "a static index.html plus
  app/classic.js and app/module.js". It is only true after the split, so it rides the apply.
  Put each import directly after the file's FIRST `import` line. `build-markers.mjs` emits an
  `import SwiftUI` inside a template string, and an import placed after the "last import line" landed in
  the generated Swift. Preflight caught that as "Markers.swift is stale".
- `tools/deploy-status.mjs`: add `'app'` to the client paths, or an `app/*.js`-only change reads as "no
  client push owed".

**Already split-aware on this branch, and unchanged on an unsplit tree** (no `wire` step needed):
- `tests/ten-capture.mjs`
  - **Served bytes:** it hashes each `/app/*.js` it serves into the row's `documentsServed`, keyed
    `/app/classic.js` / `/app/module.js` with the query dropped. D's `provenance-r3.py` maps that key to
    `git show <sha>:app/<file>`, so it proves every served byte against the commit with no change to D's
    tool.
  - **Disk and dirty:** `indexSha256Disk` keeps its meaning. `appSha256Disk`, `appSha256DiskAfter` and
    `joinedSha256Disk` are added (split trees only), and `indexDirty` now covers `app/` too.
  - **Console attribution:** a frame in `/app/<file>` gets `indexLine` in the joined numbering
    (`joinedLineOffsets`), so the report's source column survives the split.
- `tests/ten-report.mjs`: both source paths read the joined file. The disk path uses
  `readAppSource(root, { strict: false })`. The `--ref` path uses `git show <sha>:index.html` plus
  `git show <sha>:app/<file>` through `appSourceOf`.
- `tests/fixtures/season-book/build-review.py`: on a split tree it reads
  `node tools/split-scripts.mjs join`.

**Everything above lands with the apply**: `split` + `wire` in one commit. The follow-ups below are
not exercised by tonight's proof.

| follow-up | lands | why |
|---|---|---|
| CLAUDE.md's Architecture wording (proposal in §9) | **with the apply** (owner / root) | Otherwise every session starts from "single-file PWA, four blocks", which is false after the split. |
| AGENTS.md line 101 ("single-file PWA in `index.html`") | **with the apply** (root) | Same reason, for Codex sessions. |
| `tests/ten-capture.mjs` provenance + `indexLine` | **built on this branch** (lands with the branch) | Proven: `provenance-r3.py` holds every served byte, `app/*.js` included, to `git show` of the scratch split commit (§7). |
| `tests/ten-report.mjs` both source paths | **built on this branch** | Reads the joined source from disk or from `git show`. |
| `tests/fixtures/season-book/build-review.py` | **built on this branch** | Byte-identical output on the split and unsplit trees. |
| `package.json` description | **in `wire`** (with the apply) | True only after the split. |
| `season-book.test.mjs` into CI's unit step | root's call (not done here) | It is the only `tests/*.test.mjs` CI does not run, which is why it went red unseen at `561d5c12`. Its fix is on this branch (`a9ed6d06`). |

Details:
- `tests/ten-capture.mjs`
  - Console attribution: `indexLine` only recognises frames from `/` and `/index.html`. Tonight's door +
    home run carried the same 209 console messages in both trees, but only 50 of them kept an
    `indexLine` after the split, against 183 before. The `src` names `/app/classic.js?v=…` or
    `/app/module.js?v=…` instead, so `ten-report.mjs`'s "index.html line / source" columns go blank for
    script frames. The fix maps such a frame with `joinedLine(root, file, line)` (in the tool; also
    `node tools/split-scripts.mjs joined <file> <line>`). Capture pass/fail and the normal/exception
    counts were identical; this is triage only.
  - Provenance: `diskIndexSha` should hash `readAppSource(ROOT)`, and `gitDirty` should include `app`.
    Captures work without this; only the manifest's "which bytes" claim narrows.
- `tests/ten-report.mjs` git path (`git show <sha>:index.html`): for a split commit, join from
  `git show <sha>:app/…`.
- `tests/fixtures/season-book/build-review.py`: read
  `node tools/split-scripts.mjs join --root <root>` instead of `index.html`. It pulls production
  functions, which move to `app/classic.js`.
- Docs that say "single-file PWA (`index.html`)": CLAUDE.md's Architecture, `package.json`'s
  description, AGENTS.md. CLAUDE.md is the owner's (agents may not edit it). Name the change in the handoff.
- `netlify/edge-functions/share-preview.ts`: **no change**. Its regexes still match the split
  `index.html`, because the bridge keeps the exact text. `check` guards this (R13).
- `netlify.toml`: **no change**.
  - The CSP's `script-src 'self'` covers `/app/*`.
  - Netlify's default revalidating cache headers stay deliberately; see risk R6. Confirm them on the
    preview with `curl -sI`.

## 5 · Risks, each with its guard

| # | risk | guard |
|---|---|---|
| R1 | Boot order changes (classic after module, or deferred) | Tags written in place, no `defer`/`async`. `check` fails on `defer`/`async` on any script tag, and on the module tag preceding the classic one (controls `defer`, `order`: FAIL). Harness door + home pixel-identical (§7). |
| R2 | The tokenizer boundary moves (a `</script>` or `<script` inside a block) | The split refuses unless the file holds exactly four `<script` openings and no moved block contains a script-tag sequence. `check` re-splits the joined file on every preflight (control `tag`: FAIL). |
| R3 | A new file 404s (the `dist/` allowlist) | `cp -r app "$DIST/app"`; `check` fails without it (control `copy`: FAIL), and the non-empty loop fails the build if either file is missing. Preflight check 4 holds the SW SHELL to the allowlist. Proven: `COMMIT_REF=… bash stamp-version.sh` lists `dist/app/{classic,module}.js`. |
| R4 | The stamp misses a moved placeholder | `app/module.js` sits in the sed loop and the survival grep. `check` reads the `for file in …; do` loop itself (control `stamp`: FAIL). The build still fails on a surviving placeholder, as today. Preflight check 1 still counts four placeholders in the joined file. |
| R5 | Offline boot breaks (the shell is cached, the scripts are not) | SW SHELL precaches both files under `?v=' + VERSION`. `check` fails without it (control `sw`: FAIL). |
| R6 | Deploy skew: a new shell with an old script, or the reverse | The `?v=<sha>` query makes each shell name its own scripts, and each SW cache holds the pair for its version. `/app/*` keeps Netlify's default revalidation; never `immutable`. A load that races the atomic deploy flip could otherwise pin the new bytes under the old URL for a year. A racing load at worst boots once with mixed bytes, and the next navigation (network-first) heals it. |
| R7 | A reader silently scans a JS-less `index.html` | `readAppSource` throws unless the file is either the exact split layout or the whole four-block single file. A half split, a renamed tag or an added `defer` all throw. |
| R8 | Late lane hunks do not merge onto the split tree | Apply last, after every lane merge. Recipe for a late hunk in §6 (join, apply, re-split). After the split, lanes edit `app/*.js`. |
| R9 | Error messages and line citations | Today an inline error reads `@ :<line>`, with the page URL's tail as its filename. After the split it reads `@ classic.js?v=<sha>:<line>` or `@ module.js?v=<sha>:<line>`, which names the file and the build. Readers keep the pre-split numbering (the joined file), so every `index.html:N` pin, baseline and doc citation still resolves. `node tools/split-scripts.mjs where N` maps it to the real `file:line`. |
| R10 | MIME or `nosniff` rejects the module | `.js` extension only. Verify on the deploy preview: `curl -sI <preview>/app/module.js` shows a `javascript` content type. |
| R11 | A first visit gets slower on a real network (two more requests) | The preload scanner fetches both while the HTML parses; Netlify serves HTTP/2. Measured cold at zero latency the split is faster (§7). A throttled-network before/after on the deploy preview is root's step 6. |
| R13 | Share previews go generic. `share-preview.ts` parses `SUPABASE_URL` / `SUPABASE_KEY` out of the origin HTML, and a plain move would take both lines into `app/module.js`. Every `/?share=TOKEN` link would then fail open to the static brand card, with no error. | **Fixed in the split itself.** The two lines stay in `index.html`, verbatim, in the inline bridge, and the module reads them from `window`. **Guard:** `check` reads the edge function's own `html.match(/…/)` regexes out of `share-preview.ts`. It fails if either no longer matches the split `index.html`, or if the value it captures is not the one the app uses. If the regexes can no longer be found, it fails as "went blind". **Controls:** two, both FAIL with the R13 message: the previous split without the inline constants (the tool at `2d250a15`), and the bridged split with the bridge removed. Preflight on the first also fails, at its first read: `readAppSource` refuses a split without the bridge. |
| R12 | Unproven by the freeze | Owner's rule: root ships without it; first push after launch. Nothing here is committed to `index.html`, so not applying it costs nothing. |

## 6 · Root's apply-and-verify steps (tomorrow, at the final merged head)

```bash
cd <integration worktree>              # clean tree, every lane merged
git log -1 --format=%H                 # record the head the split is applied to
node tools/split-scripts.mjs split --dry           # refuses on any other shape; prints sizes
node tools/split-scripts.mjs split                 # writes index.html + app/*.js; re-joins from disk and compares sha256
node tools/split-scripts.mjs wire --dry            # lists the 16 files it will edit (15 + package.json); refuses on any moved anchor
node tools/split-scripts.mjs wire                  # §4's edits: stamp-version.sh, sw.js (never its VERSION line), preflight, the readers
git diff --stat                                    # index.html, app/ (new), and exactly those 16 files
node tools/split-scripts.mjs check                 # [split] ok · round trip exact · joined sha256 …
node tests/preflight.mjs                           # 0 failures; vs the pre-split run, the only differences are:
                                                   #   + split layout PASS, sw shell 4 -> 6 assets, 21b sources +2
node tools/build-markers.mjs --check               # ok (Markers.swift unchanged)
for t in rating homefold trophycase sunningdale post-request attribution-trace share-consent-flow; do node tests/$t.test.mjs || echo FAIL $t; done
COMMIT_REF=$(git rev-parse HEAD) bash stamp-version.sh && ls dist/app && grep -o 'src="/app/[a-z]*\.js?v=[a-z0-9]*"' dist/index.html
rm -rf dist
```

Then the proof pair, with the pre-split head as the control:
1. `git archive <pre-split head>` into a scratch dir; link `node_modules`.
2. `node tests/ten-capture.mjs --root <split tree> --port <p> --out <A> --only door,home --widths 402 --themes dark --workers 1`,
   then the same with `--root <pre-split scratch>` and `--out <B>`. Pass: 0 errors and 0 page errors on
   both, and every PNG in A byte-identical to B (tonight: 85/85).
   Then, with the split commit's sha: `python3 <gallery>/evidence/r3-prep/tools/provenance-r3.py --sha <split sha> --gallery <A> --snap <split tree> --repo <integration checkout>`.
   Pass: `usable: true`, with `documents` listing `/`, `/app/classic.js` and `/app/module.js`, each
   `match: true`. It is D's tool, unchanged.
3. `node tools/split-scripts-measure.mjs --before <pre-split scratch> --after <split tree> --out <M> --cpu 4 --runs 3`.
   Pass: no errors or gaps, both files served, main-thread compile lower, CLS unchanged.
4. One commit, `Q12 · split index.html's two script blocks into app/ (tools/split-scripts.mjs)`, with the
   rules' Co-Authored-By line.
5. Deploy (the owner pushes). Then:
   - `curl -s https://cupseason.app/ | grep -o 'app/[a-z]*\.js?v=[a-z0-9]*'` names the deployed SHA;
   - `curl -sI https://cupseason.app/app/module.js` shows 200 and a JavaScript type;
   - `#obCaption` reads `v23 · <sha>`, and Settings' foot shows the same SHA (the module file's stamp).
   - R13: `curl -s "https://cupseason.app/?share=<a live test share token>" | grep -o 'og:image" content="[^"]*'`
     shows the token's own image, not `og-image.png`, exactly as before the split.
6. On the phone, with the installed PWA:
   - open once online, then airplane mode, then reopen. The app boots from the SW cache, which proves R5.
   - on the deploy preview, a 4× CPU + Fast 4G DevTools run against the previous deploy covers R11 (the
     network the harness cannot model).

If any step fails and cannot be fixed within the freeze, undo it:
- before the commit: `git checkout -- . && rm -rf app`, which undoes both `split` and `wire`;
- after the commit: `git revert <the split commit>`.
Either restores the single file exactly. Then ship without the split (R12).

**A late lane hunk after the split** (git cannot follow a hunk into a new file). The joined file uses the
pre-split line numbering, so a lane's `index.html` diff applies to it unchanged:

```bash
node tools/split-scripts.mjs join --out /tmp/joined.html && cp /tmp/joined.html index.html && rm app/classic.js app/module.js
git diff <lane-base> <lane-head> -- index.html | git apply --3way
node tools/split-scripts.mjs split && node tools/split-scripts.mjs check
```

Tested tonight with plain `git apply` on the scratch copy. A lane diff with one hunk in the classic block
and one in the module block came back as exactly those two hunks in `app/classic.js` and `app/module.js`.
`index.html` was byte-unchanged, and `check` was ok. `--3way` falls back to the blobs when the context has
moved.

## 7 · Evidence tonight (prototype on `git archive e033161d`, scratch only)

**Capture provenance and attribution on a split tree (19:28–20:00 MST).** The split of `e033161d`,
wired, was committed in a scratch git repo (`8610ce87`, then `333258df` with the final harness). Nothing
there is a real commit.
- **Provenance.** `ten-capture` ran door + home at 402 dark: 50 captures, 0 errors. D's
  `provenance-r3.py`, unchanged, run with `--sha <scratch commit> --snap <tree> --repo <scratch repo>`,
  reports **`usable: true`**:
  - 50/50 rows served the commit's `index.html`;
  - `documents` holds `/`, `/app/classic.js` and `/app/module.js`, each with `match: true` over 50 rows
    against `git show <sha>:<file>`;
  - `indexDirty` is false and no harness file is dirty.
  - The manifest's `joinedSha256Disk` is `4cd3173c0c75…`: the pre-split `index.html`'s hash, carried by
    the split tree.
- **Controls.** Both runs used one byte appended to `app/module.js`, uncommitted:
  - the new harness gives `usable: false`, "served documents differ from the commit: /app/module.js"
    plus "manifest says index.html was dirty";
  - the harness at `e033161d` gives **`usable: true`**, having served and checked only `/`. The tampered
    script goes unseen: this is the gap the change closes.
- **Attribution.** Of 209 console messages, 183 carry `indexLine`, the same count as the unsplit run
  (was 50 before the change). The (text, `indexLine`, call chain) triples are identical on all 50 rows.
  `ten-report`'s console table is **identical** to the unsplit report's, through the disk path and
  through the `git show` path. The report tool at `e033161d`, run on the same manifest, differs in 12
  lines (wrong source text). Item 1 alone (served-bytes hashing, attribution untouched) attributes 3 of
  12 messages on the three-state check, against 12 of 12 with item 2.
- **Unsplit trees are unchanged.** On `e033161d` the new harness writes the same manifest keys and the same
  rows as the harness at `e033161d`. The only difference is one row's `supabaseRequests` (80 vs 79), a
  count that also moves between 79 and 80 across runs of the old harness alone on the same tree.
- **Pixels.** 83/85 PNGs are byte-identical to the unsplit tree's. The two that are not
  (`door/code-error` at 375×380 and 402) also differ between two runs of the old harness on the unsplit
  tree itself: timed states, not the split.
- **Cost.** Reading the two script bodies from the response takes 122–196 ms per file, in parallel, and
  only on a split tree. The machine's load average was 185–220 during these runs, so wall times are noise.
- **`build-review.py`.** Its output is byte-identical on the split tree, on the unsplit tree, and against
  the original script on the unsplit tree (868,460 B). Control: the original script on the split tree
  fails with `ValueError: substring not found`.

**Re-proof with the R13 bridge (19:14–19:16 MST, the committed tool).** On a fresh
`git archive e033161d`, run `split` + `wire`:
- `check`: ok, round trip exact, joined sha256 `4cd3173c0c75…`, the same as the original `index.html`'s.
- `share-preview.ts`'s own regexes match the split `index.html` and capture the app's values.
- Preflight: **PASS, 0 failures**, and the same three-line diff against the unsplit run.
- The seven static suites give identical output (modulo timings); `build-markers --check` is ok.
- Stamp: `dist/index.html` and `dist/app/module.js` keep 0 placeholders, and the bridge's text ships in
  `dist/index.html`.
- Harness, door + home at 402 dark: 50 captures, 0 errors, 0 page errors and 0 fixture gaps. **85/85 PNGs
  are byte-identical** to the unsplit tree's, with the same 209 console messages.
- Controls, every one of which fails: the two R13 controls (§5), plus the six layout controls rebuilt on
  the bridged split (`sw`, `defer`, `stamp`, `tag`, `order`, `copy`).
- The measurement table below was taken on the pre-bridge split. The bridge adds 561 bytes to
  `index.html` and one ~12-line inline script, which is negligible for parse/compile and was not re-measured.

The earlier (pre-bridge) run:

- **The apply, end to end.** On a fresh `git archive e033161d`, `split` + `wire` alone gave a tree
  identical to the hand-proven one. The only differences are the order of preflight's two new imports and
  check 1b's stricter single-file branch. Preflight on it: **PASS, 0 failures**, with the same three-line
  diff against the unsplit run. Then:
  - `build-markers --check` ok and sunningdale ok;
  - the stamp reads `?v=0123456`;
  - a second `wire` refuses: "already wired", nothing written;
  - control: preflight FAILS "split layout" when a SW precache entry is removed.
- **Round trip.** `split` then re-read from disk: joined sha256 `4cd3173c0c75…` equals the original
  `index.html`'s.
- **Preflight.** Unsplit copy: PASS, 0 failures. Split copy with the §4 edits: PASS, 0 failures. The diff
  holds only three lines:
  - `split layout` PASS (new);
  - `sw shell within dist allowlist` 4 → 6 assets;
  - check 21b "593 → 595 sources".
  Every other check read identical bytes.
- **Suites.** rating, homefold, trophycase, sunningdale, post-request, attribution-trace and
  share-consent-flow pass on both copies, with identical output modulo timings. `season-book.test.mjs`
  fails **identically on both** (`ReferenceError: document is not defined`). That is a pre-existing
  failure at `e033161d`, not this change.
- **Stamp.** `COMMIT_REF=abc1234def5678 bash stamp-version.sh` on the split copy. `dist/app/` holds both
  files, the tags read `?v=abc1234`, the settings foot in `dist/app/module.js` reads `v23 · abc1234`, and 0
  placeholders survive.
- **Harness, signed out and signed in.** `ten-capture --only door,home --widths 402 --themes dark`:
  50 captures each, 0 route failures, 0 errors, 0 fixture gaps and 0 page errors on both trees. **All 85
  PNGs are byte-identical** between the split and unsplit trees.
- **Controls.** `check` FAILS on each broken layout:
  - `sw` (a precache entry removed);
  - `defer` (defer on the classic tag);
  - `stamp` (module.js dropped from the sed loop);
  - `tag` (a `</script>` inside a block);
  - `order` (module before classic);
  - `copy` (`cp -r app` dropped from the allowlist).
  It passes on the split tree and reports the single file as such.
- **Measurement.** `tools/split-scripts-measure.mjs`, using AW2-01 / AW2-12's method:
  - cold load, 375×667, dark, `Emulation.setCPUThrottlingRate` 4×;
  - synthetic world, CDN replay, in-process serving;
  - median of 3, before/after interleaved;
  - plus a Chrome trace split by thread.

| 375 · 4× CPU · cold | door before | door after | home before | home after |
|---|---|---|---|---|
| main-thread script parse/compile (ms) | 103.8 | **56.7** | 144.2 | **94.2** |
| — of it top-level `v8.compile` + `v8.compileModule` (run 0) | 49.4 | 0.3 | 47.0 | 0.3 |
| background parse (`v8.parseOnBackground`, ms) | 7.6 | 20.6 | 7.0 | 19.0 |
| `ParseHTML` on the main thread (ms) | 184.0 | **121.7** | 223.2 | **149.0** |
| CDP `ScriptDuration` (ms) | 87.3 | 90.6 | 109.5 | 99.1 |
| FCP (ms) | 152 | 124 | 156 | 120 |
| DOMContentLoaded (ms) | 341 | 239 | 342 | 233 |
| ready (door `#obEmail` / Home settled, ms) | 381 | 278 | 589 | 437 |
| CLS | 0.0006 | 0.0006 | **0.8187** | **0.8187** |
| page errors · fixture gaps | 0 · 0 | 0 · 0 | 0 · 0 | 0 · 0 |

(Per-row ranges for main-thread compile: door 98.8–110.9 → 55.2–84.5; home 132.9–144.2 → 80.1–131.0.
Raw: `measure.json` in the scratch run.) End state in every run, both trees:
- `window.CS` and `window.sb` are objects and `window.renderFormation` is a function;
- `bootStep` reads `reveal`;
- the split runs served `/index.html`, `/app/classic.js` and `/app/module.js`.

**Reading it:**
- The top-level parse of both blocks leaves the main thread; it streams on V8's background thread. The
  HTML tokenizer no longer walks 1.9 MB of script text.
- Lazy function compiles (`V8.CompileCode`) stay on the main thread. On repeat visits the V8 code cache is
  what shrinks them. That cache is not measured here: Playwright's routing disables the HTTP cache, so these
  are cold loads only.
- **CLS is unchanged.** The split neither fixes nor worsens AW2-01's Home jump (0.8187 in both trees).
  That P1 is a render-order fix (Q12 part 1), not a parse fix.

## 8 · Phone half (D234)

None. This is the web client's delivery structure. No producer, copy, RPC or layout changes, and the phone
has no twin.

## 9 · Proposed CLAUDE.md wording (for the owner and root at apply time; not edited here)

This replaces the Architecture bullet's first line and its "Four script blocks" paragraph:

> - **Client:** a PWA of one page and two scripts: `index.html` (the CSS, the markup and three small
>   inline scripts) plus `app/classic.js` and `app/module.js`. It is **dark-first** … *(the theme text is
>   unchanged)*.
>   Five script blocks, in document order:
>   1. the pre-paint theme (inline, in `<head>`);
>   2. the `#errbar` handlers and SW registration (inline);
>   3. `app/classic.js`, the classic UI and its boot render chain, parser-blocking with no `defer`/`async`;
>   4. the Supabase bridge (inline), which sets `window.CS_SUPABASE_URL` / `_KEY`. The share-preview edge
>      function parses those two const lines out of the HTML, so edit the key there and only there;
>   5. `app/module.js` (`type="module"`: the Supabase client, auth, the data layer).
>
>   Both files load as `/app/<file>?v=__CS_VERSION__`. The build stamps the query, and `sw.js` precaches
>   each file under the same query. `tools/split-scripts.mjs` made the split. Its `readAppSource()` gives
>   every static reader (preflight, the suites) the single-file text back, byte for byte, with the old line
>   numbers, and `check` (preflight's "split layout") guards the layout.
>
>   **The classic ↔ module boundary is a landmine.** Module top-level names are NOT visible to classic
>   scripts; bridge explicitly via `window.*` (see `window.CS`, `window.sb`, `window.renderFormation`). The
>   classic boot render chain runs BEFORE the deferred module executes, so guard any classic reference to a
>   module export with a `window.X?.` existence check. A new served file goes into `stamp-version.sh`'s
>   allowlist and `sw.js`'s SHELL, or it 404s or breaks offline.

Two other CLAUDE.md lines need the same care at the apply:
- "Deploy & verify": a pure-client change now includes `app/*.js`.
- "index.html has MIXED middot encodings": this holds for `app/*.js` too, because the bytes moved unchanged.
