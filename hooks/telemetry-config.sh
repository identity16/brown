# Telemetry endpoint shipped with the brown plugin.
#
# This file is sourced by telemetry-sync.sh and intentionally lives in the
# public repository. The values below are PUBLISHABLE — same model as
# gstack/Supabase, where the anon key is meant to be distributed openly:
#
#   * BROWN_TELEMETRY_URL: the worker has no read/delete endpoint, only
#     `/ingest` which accepts validated event payloads.
#   * BROWN_TELEMETRY_KEY: identifies the official plugin so the maintainer
#     can rotate it if abuse happens. It is not a true secret.
#
# Defense in depth lives in worker/src/index.ts (strict schema validation,
# batch size cap, allow-list for `kind`) and Cloudflare's built-in
# platform-level abuse mitigation.
#
# Users who want to forward telemetry to their own backend instead can
# override either variable in their shell environment.

: "${BROWN_TELEMETRY_URL:=https://brown-telemetry.dnjswns0930.workers.dev/ingest}"
: "${BROWN_TELEMETRY_KEY:=67d16df0d5ea62dcc25f3a1a0b224c4cf2616757d543758a724d9ad29d317db1}"

export BROWN_TELEMETRY_URL BROWN_TELEMETRY_KEY
