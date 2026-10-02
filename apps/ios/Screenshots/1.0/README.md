# The 1.0 App Store set · iPhone 6.9" · APPROVED AND UPLOADED 2026-10-02

Recaptured 2026-10-01 on the owner's "Recast for the store". **Approved and uploaded 2026-10-02** (the owner:
"All 9, with widgets"). Order, headlines
and captions are §9 of [the App Store package](../../../../docs/ios/app-store-package-2026-09-30.md),
which supersedes [SHOT-LIST.md](../SHOT-LIST.md) for 1.0. The cast is invented: no real golfer, owner
name, real course, price or ledger appears (§9's capture rules, X37).

- **Source:** `a48dac68`, which is candidate 2 (`6727fd04`) plus a DEBUG-only store cast: the shipped
  Release code is unchanged.
- **How:** every frame is a `-cs_dev_synthetic` launch with `-cs_dev_cast store`, on an iPhone 17 Pro
  Max simulator (iOS 26.5), with a 9:41 status bar and the default reading size. Frame 9 is the What's On
  and The Race widgets on a real Home Screen.
- **Checks:**
  - Each screen was verified against its accessibility tree.
  - An audit of the on-screen text and OCR of the pixels found zero findings in all nine frames: no real
    names, real courses, dollar figures, raw machine strings, debug chrome or test-looking names.
  - Every file is 1320 × 2868, 8-bit RGB, no alpha.
  - **Checked against the build that ships (2026-10-02).** All nine were retaken from `c8cd8ea3`,
    the commit build 2114 was archived from (main's `ebbbfea3` has the same files), with a clean
    audit. 02–05 match the committed files to within noise. 01, 06 and 07 differ only in the
    synthetic world's dates, one day later, and one points total. 08 differs only in where the
    scroll stops, about 50 points further down: that cuts the season in play and leaves a bare
    "Head to head" heading at the foot. 09 differs only in the widgets' sample standings and
    clock. The committed frames stand as the set for 2114.
  - **They stand for 2206 too (2026-10-02).** Build 2206 (`7eaefb8b`) differs from 2114 only by the
    retired forecast's code and the reviewer password field. No frame shows a planned round's sheet,
    the only screen that drew a forecast, or the reviewer door.
- **Uploaded 2026-10-02, 13:26 MST:** all nine, in this order, replaced the September 25 frames in App Store
  Connect's `APP_IPHONE_67` set (`asc_metadata.py --apply --only screenshots`). Read back: each frame
  COMPLETE at 1320 × 2868, its checksum matching the file here.
- **Known:**
  - **Frame 5 was retaken 2026-10-02 after the in-line comments build (D405).** It still shows the foot
    of the round's comment composer above the receipt, now reading "Updates from this conversation are
    on." (it read "You'll be notified of replies to you."). Retaken with `capture.sh --only 05-receipt`
    from `868dcb95` (audit clean). The synthetic world is date-relative, so one receipt row differs from
    the 2026-10-01 frame (the Mulligan Cup League line reads "BUMPED · 7 PTS", where it read "COUNTING #4
    OF 4 · 7 PTS", and the round's date is Sep 30). The retake from the commit that ships matches it
    (Checks, above).
  - Frame 9 says "AS OF 10:30 PM" (the capture's wall clock) under a 9:41 status bar.

| File | SHA-256 |
|---|---|
| 01-season.png | `459b2796b911418ea58461807fed3cd0258f2d431f291e0950f16184fd1add7b` |
| 02-composer.png | `e5f39a6c77467627616ccec0f3dd854b85f01b229e47d7efa496b30b296cd7c9` |
| 03-rivalry.png | `68e17227a34f6e2282aa4b828d7a63f69142b6046bac2fb87bf8219b8c9c323b` |
| 04-live.png | `561be5940c5f09655e91f51ecb4afb40c76b514d5e2ea7d349040fbdf6732519` |
| 05-receipt.png | `493333835f0263af7b201032e89ddccaca7eda2ce43758f9aee8020840165796` (retaken 2026-10-02; was `90f7e1db…`) |
| 06-book.png | `fd6cf6569efcbfa7b34ad491f7a67c99db231651f1d386f42cdf0f0b0157b0d1` |
| 07-ceremony.png | `4c8eeaecec2442d52e8656e93fb4c7a9ce5fb63244659133520cad1472651ddc` |
| 08-record.png | `3a1a8742bc94559057223ba6c95e489f0c3e030099e4e9d63767fb8c0bb131cd` |
| 09-widgets.png | `596bc848e1076b3866b208711e3c5e32970e1c731d36b45ddd472fd6c598f2a6` |
