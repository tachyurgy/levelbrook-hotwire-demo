# Levelbrook Workspace (Hotwire demo) — Release History

Rails 8 Hotwire showcase. Deployed to the Hetzner box (`5.78.108.109`) via Kamal
behind kamal-proxy, live at **https://demo.levelbrook.com**.

Deploy command:
`export KAMAL_REGISTRY_PASSWORD=localpw123 && export BALLOT_GEMINI_API_KEY=<key> && bin/kamal deploy`
(build runs on the box via an SSH buildx context; re-export `BALLOT_GEMINI_API_KEY`
from the live container so the redeploy doesn't blank it — `docker exec <web> printenv BALLOT_GEMINI_API_KEY`).

> Newest release on top. Append a new entry every deploy.

---

## 2026-06-02 — LinguaGuessr "bad audio" report ingest
- **What deployed:** demo.levelbrook.com, version `d593556`. New API-key-protected
  JSON endpoint that receives "report bad audio" flags from LinguaGuessr
  (lingua.levelbrook.com) so dead-air / garbled / mislabeled clips can be reviewed
  and pruned from the corpus. (Showcase apps unchanged.)
- **Changed:**
  - `bad_audio_reports` table + `BadAudioReport` model (length-capped fields,
    status open/reviewed/dismissed).
  - `Api::V1::BadAudioReportsController` — lean `ActionController::API` (no CSRF/
    browser gate), guarded by a shared `X-Api-Key` (`secure_compare`, ENV
    `BAD_AUDIO_API_KEY` overridable) + a CORS allowlist for the LinguaGuessr origin
    with an OPTIONS preflight. Routes under `/api/v1`.
  - 5 controller tests added.
- **How:** `bin/kamal deploy` (preserved the live `BALLOT_GEMINI_API_KEY`); the
  Rails entrypoint ran the new migration on container boot.
- **Verified (live, over HTTPS):** no-key POST → 401; keyed POST → 201
  `{"ok":true,"id":...}` and row persisted; OPTIONS preflight → 204 with
  `Access-Control-Allow-Origin: https://lingua.levelbrook.com`. Synthetic
  verification row deleted afterward (table back to 0).

## 2026-05-29 — Workspace rebuild
- **What deployed:** demo.levelbrook.com — the "Levelbrook Workspace" rebuild (one
  Rails 8 app spanning many Hotwire modules: Jira-grade Kanban, real-time chat +
  presence, ⌘K palette, live search/validation, infinite scroll, persistent media
  player), replacing the thin earlier 2-demo version.
- **Verified:** all module routes 200 over HTTPS, styled, board renders.

## 2026-05-28 — Initial deploy
- **What deployed:** First live deploy of the Hotwire demo to the Hetzner box via
  Kamal + kamal-proxy. DNS A record `demo` → `5.78.108.109`; Let's Encrypt TLS
  auto-issued by kamal-proxy. Caddy stopped/disabled; box-local Docker registry
  (`registry:2` @127.0.0.1:5000) used because the gh token lacks `write:packages`.
