# Complete-week design review

Open [next-week.html](next-week.html) in a browser. It is self-contained, including the existing mark, icon and bundled typeface; it works without an account or network. The golf loop and Brand proof tabs show the first review checkpoint from the next-chapter plan.

All people, dates and results are illustrative. Interactions live in memory and reset on reload. The composer is intentionally abbreviated; it does not validate the full production scorecard, call an RPC, persist a draft or upload a photo. The four moment buttons and checkboxes are review controls. The single-plan fixture does not simulate multiple plans, server races, midnight, relaunch or duplicate-write prevention.

Try Add my round, resume the existing draft, or explicitly replace it with the plan context. A kept live scorecard offers no replacement. Simulate a failed save, retry, then inspect the receipt without a photo. Later and Didn't play hide this fixture only after simulated acceptance. Older-server mode keeps ordinary entry available.

Brand proof compares the checked-in beta icon with a solid-field proposal and contour on larger surfaces. Paper/Dusk, tiny marks, circle crop, one-color stamp, three appearance specimens and five application signatures are included. These are layout specimens, not approved asset exports. The tinted proof is monochrome; OS tint, native Dynamic Type and embroidery need their own validation.

Edit `next-week.template.html`, then run from the repository root:

```sh
python3 tools/build-next-week-prototype.py
```

Do not hand-edit `next-week.html`. The generator reads `packages/tokens/tokens.json`, the current pennant source/generated mark, the checked-in app icon and IBM Plex Sans Condensed. It only writes this document artifact. No third-party dependency is added.

Reproduce the browser check with a local server on port 8797:

```sh
python3 -m http.server 8797 --bind 127.0.0.1
node tools/web-verify.mjs --url http://127.0.0.1:8797/docs/prototypes/next-week.html --out work/next-checkpoint/journey --widths 1440,390,320 --wait 700 --eval 'fetch("/docs/prototypes/next-week-check.js").then(r=>r.text()).then(s=>(0,eval)(s))'
```

The check asserts 21 interaction/layout conditions at each width. This proves prototype behavior only. See [the checkpoint review](../reviews/2026-09-12-next-checkpoint.md) for Claude's findings, Codex's disposition, evidence and the next build packet.
