# brown-telemetry worker

Cloudflare Worker that ingests anonymous brown-plugin telemetry into D1.

The maintainer's deployed instance is the default — its URL and ingest key live
in `hooks/telemetry-config.sh` and are intentionally public, same pattern as
gstack/Supabase's anon key. Real defense is in the worker code:

* only `POST /ingest` exists (no read, no delete)
* strict schema validation (`v:1`, allow-list for `kind`, 80-char field cap)
* batch size capped at 100 events per request
* Cloudflare's platform-level abuse mitigation

If you want to fork and run your own instance, this README walks you through
the same deployment the maintainer did. `wrangler.toml` is gitignored so your
`database_id` stays out of git.

## Deploy

```bash
cd worker
cp wrangler.toml.example wrangler.toml   # then edit database_id below
npm install -g wrangler

# 1) Create the D1 database and copy the printed database_id into wrangler.toml
wrangler d1 create brown_telemetry

# 2) Apply schema
wrangler d1 execute brown_telemetry --remote --file schema.sql

# 3) Set the ingest key (the plugin will send it as `x-brown-key`).
#    Generate one with: openssl rand -hex 32
wrangler secret put INGEST_KEY

# 4) Deploy
wrangler deploy
```

After deploy, point the plugin at the worker:

```bash
export BROWN_TELEMETRY_URL="https://brown-telemetry.<you>.workers.dev/ingest"
export BROWN_TELEMETRY_KEY="<the value you set via wrangler secret>"
```

## Inspect data

```bash
wrangler d1 execute brown_telemetry --remote \
  --command "SELECT kind, name, COUNT(*) c FROM events GROUP BY kind, name ORDER BY c DESC LIMIT 20"
```
