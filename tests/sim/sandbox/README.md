# The sandbox — a disposable cluster with every migration and every real function

`apply.sh` builds a throwaway PostgreSQL 17 cluster (`initdb`, no Docker, no
Supabase CLI), stubs what Supabase provides (`auth.uid()` reads the `sim.uid`
setting, the `anon` / `authenticated` / `service_role` roles exist and are NOT
superusers), then applies `supabase/migrations/*.sql` in filename order. It
never touches production and never calls the linked project.

```
tests/sim/sandbox/apply.sh                 # port 5478, socket /tmp/cs-sim-sock
PORT=5470 SOCK=/tmp tests/sim/sandbox/apply.sh
psql -h /tmp/cs-sim-sock -p 5478 -U postgres -d cupseason
```

Row security is real here. To act as a golfer: `set role authenticated; set
sim.uid = '<profile id>';`. To act signed-out: `set role anon; set sim.uid = '';`.
A statement run as `postgres` bypasses row security and proves nothing about
denial — `tests/pilot/authz-flow.py` never does that for an assertion.

Data files and logs are gitignored. The socket path must be short (macOS caps
a Unix socket path at 103 bytes), which is why the default is under `/tmp`.
