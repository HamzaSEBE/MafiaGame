# Authenticated client load tests

`clients.mjs` uses the Firebase client SDK, real Auth sign-in and live Firestore
listeners for each human. Hosts and players count toward the 100,000 total.
Admin operations in `seed.mjs` prepare fixtures and are excluded from measured
traffic. The seed test uses a persistent voting window to measure steady reads,
ballot changes and reconnects; integration tests exercise phase transitions.
It does not alone certify game lifecycle capacity.

Use a dedicated project named `mafia-staging-*` or `mafia-load-*`, never the
production project. Obtain quota and cost estimates first. Production App Check
remains required: supply a valid test App Check token to clients, and refresh it
for runs beyond its expiry. Seed users in advance to avoid new-account IP limits.

1. `npm ci --prefix tool/load` and `npm ci --prefix services/game_api`.
2. Set `GCLOUD_PROJECT`, `LOAD_PROJECT_ACK`, `GAME_ENGINE_URL`, and
   `LOAD_SEEDS_FILE` (private local path). `TARGET_CLIENTS=21 npm run seed --prefix
   tool/load` creates one room with a host and 20 players. Seed in bounded runs;
   the script does not launch a large test automatically.
3. Save public Firebase app configuration in `FIREBASE_CONFIG_FILE`. Set
   `GAME_API_URL`, `APP_CHECK_TOKEN`, `LOAD_SEEDS_FILE`, `REPORT_FILE`,
   `CLIENTS_PER_SHARD`, `SHARD_COUNT`, `SHARD_INDEX`, `CONNECT_PER_SECOND`,
   `DURATION_SECONDS`, `ACTION_INTERVAL_SECONDS`.
4. Run `npm run load --prefix tool/load`. For 100,000 clients, distribute 100
   shards of 1,000 across appropriately sized load machines. Start with 21,
   210, 2,100, 10,000, then increase under the Firestore 500/50/5 ramp policy.
   The process reports SDK connections ready, snapshots, listener count,
   commands, errors and p50/p95/p99 latency. No tokens appear in reports.
5. Repeat with `RECONNECT_PERCENT=20`, simultaneous round closes, host failures,
   cold starts, expiry cleanup, and a 60-minute soak. The ready count must reach
   the target. Aggregate shard reports, Cloud Run logs/CPU/memory/instance count,
   Firestore contention/error metrics and billed reads/writes together.

Provisional gate: all requested clients ready, successful valid commands >=99.9%,
command p95 <500ms, listener propagation p95 <1s, and no leaked private roles,
lost accepted ballots, duplicate outcomes or unbounded backlog. The script reports
command latency; measure propagation separately from coordinated host transitions.
Capacity is verified only by recorded staging results, not a local emulator run.

When using emulator Auth, also set FIREBASE_AUTH_EMULATOR_HOST during seeding.
The local SDK harness uses Auth 9099 and Firestore 8085. Store custom tokens in
files with mode 0600 and delete them and seeded Auth users after testing. Room
cleanup recursively removes children; it does not delete test Auth accounts.
