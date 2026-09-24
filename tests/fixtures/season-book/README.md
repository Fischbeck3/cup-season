# The Book contract fixtures

`run.sh` creates a fresh PostgreSQL 17 cluster in a unique `/private/tmp/cs-season-book-final-*` directory, applies the repository migration chain, seeds synthetic users/rounds, reapplies the Book migration to test idempotence, and verifies the RPC under `authenticated`. It stops only its own cluster on exit. It does not use Supabase CLI, credentials, a linked database, or any remote service.

```sh
bash tests/fixtures/season-book/run.sh
node tests/season-book.test.mjs
```

The committed JSON files were read from that real SQL implementation on September 24, 2026. They are frozen test data, not production records. Both clients validate these same envelopes. `home.json` verifies the points tie at the Compete entry. `build-native-fixtures.py` embeds them behind `#if DEBUG`; the library test copies are test-target resources only. Regeneration is explicit, using `verify.py --socket <owned-sandbox-socket> --port <owned-port> --export`, then the native generator and copies into the package's `SeasonBookFixtures` test folder. No scoring flag is authored in a renderer.

The seed includes 16 golfers, four squads, 15 weeks, 193 rounds, a shared 41-point solo lead, multiple rounds in a week, a displaced round, a zero-point bye, an individual override, a squad floor, and an adjustment outside the season weeks. The completed fixture deliberately closes early, so its scheduled end remains ahead of its completion. Its read still names the lack of a locked historical rule snapshot. Synthetic round differentials are supplied because seed loading deliberately bypasses write triggers; points and best-N flags come from the real scoring views.

`build-review.py <output-directory>` makes a disconnected browser harness around the actual production Book functions and CSS. It bundles the already-licensed native font files for offline review. The only RPC is a synthetic in-memory response; its failure toggle exercises the real error/retry UI. It never boots the production app or signs in.
