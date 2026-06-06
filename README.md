# Levelbrook Hotwire Demo

**A Rails 8 product workbench — server-rendered Rails with targeted JavaScript,
not a single-page framework.** Three focused apps share one codebase: a real-time
delivery board, a live LLM streaming chat, and an interactive playground for two
open-source Ruby gems. A gallery (`/`) routes into all three; a themeable shell
re-skins the chrome per app from a single CSS custom property.

**Live:** [demo.levelbrook.com](https://demo.levelbrook.com)

> Built by **Levelbrook Consulting** — senior Ruby on Rails engineering, on contract. · `levelbrookteam@gmail.com`

| | |
|---|---|
| **Stack** | Rails 8.1 · Hotwire (turbo-rails + stimulus-rails) · **importmap** (no Node, no bundler) |
| **Realtime / data** | SQLite · **Solid Queue** · **Solid Cable** · **Solid Cache** — no Redis, no external services |
| **Assets** | Propshaft · Tailwind v4 via `tailwindcss-rails` (no PostCSS/Node toolchain) |
| **Deploy** | Kamal 2 + kamal-proxy to a single Hetzner box |

## The three apps

| Route | App | What it proves |
|---|---|---|
| `/workspace`, `/projects/:slug` | **Workspace** | A Jira-grade Kanban: SortableJS drag → `broadcasts_refreshes` **morph** synced across tabs; a lazy Turbo-Frame issue drawer with frame-scoped inline edit; ⌘K command palette; debounced live search; infinite-scroll activity feed; per-field live form validation. |
| `/relay` | **Relay** | A live LLM chat that streams Google Gemini tokens to the browser as **Vercel AI SDK data-stream-protocol** frames, encoded over `ActionController::Live` SSE by the vendored [`ai_stream`](https://github.com/tachyurgy/ai_stream) gem — including streamed tool-call parts. |
| `/forge` | **Forge** | Interactive benches for two open-source gems: [`picoglob`](https://github.com/tachyurgy/picoglob) (bash glob → Ruby `Regexp`) and [`fzy_score`](https://github.com/tachyurgy/fzy_score) (fuzzy ranking with matched positions). Each "run" is real server-side computation by the gem, so the page is itself proof the library works. |

## What to inspect

If you're reviewing this for engineering judgment, these are the things worth a look:

- **`/workspace` → open a board, drag a card** — the move PUTs the new column+position to a thin endpoint (`issues/positions`), which broadcasts a single `broadcasts_refreshes` morph. Open the board in two tabs and watch it sync. SortableJS state is DOM-resident so the morph doesn't fight the drag.
- **`/workspace` → click a card** — the issue drawer is a lazy Turbo Frame; `/issues/:id` still works as a full page. Inline edits swap a single field's frame, not the page.
- **`/relay` → send a prompt** — watch the tokens arrive over SSE. The wire format is the Vercel AI SDK protocol; `vendor/gems/ai_stream` is the encoder. Try the "tool call" preset to see streamed tool-input/output parts.
- **`/forge/picoglob`** — type a glob; the result panel is a debounced Turbo Frame whose `src` carries the live inputs. The match logic is the real gem, not a reimplementation.
- **`app/lib/showcase.rb`** — the app registry. One row per app; the themeable shell reads it. Adding an app is one row plus its controllers/views.

## Architecture notes

- **Why importmap (no Node/bundler):** the JavaScript is a handful of small Stimulus controllers. A build step would be pure overhead. Pinned ESM from the importmap keeps the asset pipeline a single concern.
- **Why the Solid stack (Queue/Cable/Cache on SQLite):** no Redis, no Postgres accessory, no external services — the whole app is one process and one SQLite volume on one box. For a demo (and many real apps) that's the right amount of infrastructure.
- **Where Turbo morphing is used:** board sync and the dashboard snapshot refresh via `broadcasts_refreshes` + `<meta name="turbo-refresh-method" content="morph">`. Morph preserves scroll/focus and the drag's DOM state.
- **Where raw `ActionController::Live` is used:** Relay's SSE stream. Tokens are pulled from Gemini's `streamGenerateContent?alt=sse` endpoint and re-encoded as AI SDK frames by `ai_stream`, written to `response.stream`.
- **What the tests prove:** the Ruby suite covers models, controllers, and the full Workspace flow; the Playwright suite drives real Chromium for the things unit tests can't (cross-tab broadcasts, debounced frames, ⌘K, per-field validation).

## Running locally

```bash
bin/setup            # installs gems, prepares DBs, seeds
bin/dev              # boots Puma (+ Solid Queue in-process) and Tailwind watch
# open http://localhost:3000
```

Relay needs a `GEMINI_API_KEY` (or `GOOGLE_AI_API_KEY`) in the environment to
stream; without it, Workspace and Forge run fully offline.

## Testing

```bash
bin/rails test                       # 85 model + controller + integration tests
bundle exec rubocop                  # clean

cd e2e && npm install && npx playwright install chromium
npm test                             # Playwright browser tests vs a booted server
```

## Project map

```
app/models/         project, column, issue, comment, member, activity, signup
app/controllers/    workspace (top-level) + relay/ and forge/ namespaces + api/v1 (lingua ingest)
app/lib/showcase.rb the app registry — one row per app; the themeable shell reads it
app/javascript/controllers/   Stimulus controllers (sortable, command_palette, inline_edit, ai_stream, …)
vendor/gems/        ai_stream, picoglob, fzy_score (vendored path gems, dogfooded by Relay + Forge)
e2e/                Playwright suite (own package.json; touches nothing in app/)
test/               minitest suite
```

## Deploy (Kamal 2 → one Hetzner box)

Everything is configured in `config/deploy.yml`; a box-local Docker registry and a
remote amd64 buildx context handle builds. The app is **live at
[demo.levelbrook.com](https://demo.levelbrook.com)** behind kamal-proxy (auto Let's
Encrypt TLS). SQLite + Solid Queue/Cable/Cache all run on the single box (a
persistent volume holds the SQLite files) — no database or Redis accessory.

```bash
export KAMAL_REGISTRY_PASSWORD=<registry token>
bin/kamal deploy
bin/kamal app exec "bin/rails db:seed"     # seed/refresh demo data on the box
```

> Gotcha: the prod volume persists the SQLite files. If a schema change conflicts
> ("table already exists"), clear the `*.sqlite3` files in the
> `levelbrook_hotwire_demo_storage` volume (no real data) before `kamal deploy`,
> then re-run `db:seed`.

## Known limits (what I'd change for a real client)

This is a demo, and it makes demo tradeoffs on purpose. Being explicit about them:

- **SQLite + Solid stack on a single box** is great for a demo and small apps, but a
  real multi-instance deployment would move to Postgres and a shared cache/queue
  backend. The app code wouldn't change much; the infra would.
- **The activity feed is assembled in Ruby on every read** (`Activity.build`). The
  source tables are tiny so it's cheap here; at scale you'd cache it under a key
  derived from `max(updated_at)` of the source tables, or back it with a real table.
- **Demo identity is a cookie-pinned `Member`**, not real auth. A production version
  would have proper accounts, authorization, and per-tenant scoping.
- **Relay depends on a third-party model.** It retries transient 5xx/429s and falls
  back to a second Gemini model, but a production integration would add request
  budgets, abuse limits, and observability around the provider.
- **Seed data is illustrative**, not real customer data — assignees and comment
  authors are role labels, not people.
