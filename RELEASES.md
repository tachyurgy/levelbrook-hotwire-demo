# Levelbrook Workspace (Hotwire demo) — Release History

Rails 8 Hotwire showcase. Deployed to the Hetzner box (`5.78.108.109`) via Kamal
behind kamal-proxy, live at **https://demo.levelbrook.com**.

Deploy command:
`export KAMAL_REGISTRY_PASSWORD=localpw123 && export BALLOT_GEMINI_API_KEY=<key> && bin/kamal deploy`
(build runs on the box via an SSH buildx context; re-export `BALLOT_GEMINI_API_KEY`
from the live container so the redeploy doesn't blank it — `docker exec <web> printenv BALLOT_GEMINI_API_KEY`).

> Newest release on top. Append a new entry every deploy.

---

## 2026-06-05 — Relay: fix invisible streaming + viewport-freeze the demo
- **What deployed:** demo.levelbrook.com/relay, commit `acdbea9`. Same 8-app gallery; the Relay page is rebuilt and its streaming actually works visibly now.
- **Changed:**
  - **Visible streaming (the core fix):** Gemini batches output into ~3 large chunks, so token streaming was never visible. `MessagesController#emit_smoothly` now re-emits each chunk word-by-word (~18ms pause) — prod went from **3 `text-delta` frames to 435** for one answer.
  - **Resilience under load:** `gemini-2.5-flash` intermittently 503s ("high demand"), which surfaced as a bare error / "nothing streamed". `GeminiService.stream_text` now retries transient 503/429 (`Overloaded`) and falls back to `gemini-2.0-flash`; retries fire only before any token is yielded so output can't duplicate.
  - **2nd message dead:** `ai_stream_controller.js` used `this.emptyTarget?.remove()`, but Stimulus target getters *throw* when missing — so the 2nd send threw `Missing target "empty"` and left `streaming` stuck true, silently dropping all later sends. Guarded with `hasEmptyTarget`/`hasSuggestionsTarget`.
  - **Design / "goes to top" / not viewport-frozen:** view rebuilt as a single screen pinned to `calc(100dvh - 3.5rem)` with `overflow:hidden`; only the transcript + wire inspector scroll internally. Removed the sprawling applications grid and the black-on-black "how it works" code block (its `text-[#e8e6df]` utility was never compiled into the build).
  - **Richer prompts:** the 4 presets now elicit substantive multi-paragraph answers; system prompt targets 120–220 words so streaming is clearly visible.
- **How:** `cd ~/Desktop/levelbrook-hotwire-demo && export KAMAL_REGISTRY_PASSWORD=localpw123 && bin/kamal deploy` (BALLOT_GEMINI_API_KEY already wired through Kamal).
- **Verified:** Prod page HTTP 200; live Gemini SSE stream emits **435 `text-delta` frames** for one answer (was 3). Headless-Chromium against **prod**: `document` scroll == 0 (viewport frozen), zero console/page errors, first + second messages both stream (the previously-broken path), wire inspector populates, captured mid-stream at `text-delta ×236`. Same checks passed locally before deploy.

## 2026-06-05 — Relay (ai_stream + Gemini) & Forge (picoglob/fzy_score) showcase apps
- **What deployed:** demo.levelbrook.com, gallery grown from 6 to **8 apps**. New: **Relay** (`/relay`) — a live LLM chat streaming Google Gemini token-by-token to the browser as Vercel-AI-SDK data-stream-protocol frames, encoded by the vendored `ai_stream` gem over ActionController::Live SSE, with a live wire inspector + calculator tool-call demo + streamed `data-*` suggestions. **Forge** (`/forge/picoglob`, `/forge/fzy`) — interactive server-computed playgrounds dogfooding `picoglob` (glob→Regexp) and `fzy_score` (fuzzy ranking w/ matched-position highlight).
- **Changed:** Vendored ai_stream/picoglob/fzy_score as path gems under `vendor/gems/`; added `GeminiService.stream_text` (SSE token stream) + a safe `calculate` tool; registered both apps in `Showcase::APPS` + sidebar + namespace→shell mapping; refreshed gallery masthead. No new models/migrations (stateless — persistent SQLite volume untouched). **Dockerfile fix:** `COPY vendor/* ./vendor/` → `COPY vendor/ ./vendor/` (the wildcard flattened `vendor/gems/`, dropping the path gems at build).
- **How:** `cd ~/Desktop/levelbrook-hotwire-demo && export KAMAL_REGISTRY_PASSWORD=localpw123 && bin/kamal deploy` (BALLOT_GEMINI_API_KEY already wired through Kamal; GeminiService model = gemini-2.5-flash).
- **Verified:** All new routes HTTP 200 over HTTPS (`/forge`→302→picoglob as designed). Gallery renders Relay + Forge cards. Live **prod** Gemini SSE stream confirmed: real token deltas + correct protocol frames (`start`/`text-start`/`text-delta`/`text-end`/`data-suggestions`/`finish`/`[DONE]`); tool path emits `tool-input-*`/`tool-output-available` (calculator returns 4195 for (47×89)+12). Both gem playgrounds compute live in prod. Browser interaction + layout screenshot-checked locally before deploy. Pre-existing Grid::CellsControllerTest failures (3) predate this change.

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
