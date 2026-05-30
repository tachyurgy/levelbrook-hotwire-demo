# Levelbrook Hotwire Showcase

**Six real, production-shaped apps in one Rails 8 codebase — zero SPA.** Each app
is a focused demonstration of something people assume requires React/Vue, built
with **Hotwire (Turbo 8 + Stimulus)**, Action Cable, and the Solid stack. One
gallery (`/`) routes into all six; a themeable shell re-skins the chrome per app
from a single CSS custom property.

> Built by **Levelbrook Consulting** — senior Ruby on Rails staff augmentation. · `levelbrookteam@gmail.com`

| | |
|---|---|
| **Stack** | Rails 8.1 · Hotwire (turbo-rails + stimulus-rails) · **importmap** (no Node, no bundler) |
| **Realtime / data** | SQLite · **Solid Queue** · **Solid Cable** · **Solid Cache** — no Redis, no external services |
| **Assets** | Propshaft · Tailwind v4 via `tailwindcss-rails` (no PostCSS/Node toolchain) |
| **Deploy** | Kamal 2 + kamal-proxy to a single Hetzner box |

## The six apps

| Route | App | The Hotwire idea it proves |
|---|---|---|
| `/workspace`, `/projects/:slug` | **Workspace** | Jira-grade Kanban: SortableJS drag → `broadcasts_refreshes` **morph** across tabs; lazy Turbo-Frame issue drawer; zero-latency inline edit; ⌘K palette; debounced search; infinite-scroll feed; live form validation |
| `/channels` | **Cadence** | Realtime chat: `broadcast_append_to` for messages, `broadcast_replace_to` for reactions, **raw Action Cable** for presence + typing (ephemeral, not DOM-over-the-wire) |
| `/pulse` | **Pulse** | Live ops dashboard: background **Active Job → Turbo Stream** progress with no polling; server-rendered SVG sparklines that morph; acknowledge/resolve incidents |
| `/ballot` | **Ballot** | Live polls & Q&A: optimistic UI reconciled by a morph; per-client "voted" state surviving the morph via Stimulus; CSS-bar charts, no charting JS |
| `/grid` | **Grid** | Spreadsheet: frame-scoped cell editing; **server-computed formula cells** (row total + grand total) recomputed and morphed onto every client |
| `/spindle` | **Spindle** | A music player that keeps playing as you browse — `data-turbo-permanent` element owning one Web Audio graph; tracks synthesized live (no audio files) |

Each app has a full technical write-up in [`blog/`](blog/) (one self-contained
HTML doc per app) — see [`blog/index.html`](blog/index.html).

## Running locally

```bash
bin/setup            # installs gems, prepares DBs, seeds
bin/dev              # boots Puma (+ Solid Queue in-process) and Tailwind watch
# open http://localhost:3000
```

Manual steps:

```bash
bundle install
bin/rails db:prepare                 # creates + seeds primary, cache, queue, cable DBs
SOLID_QUEUE_IN_PUMA=1 bin/rails server
```

Development uses the **same multi-database setup as production** (`primary`,
`cache`, `queue`, `cable`), with Solid Cable for Action Cable and Solid Queue
running inside Puma — so the realtime and background-job paths you see locally are
the ones that ship.

## Testing

```bash
bin/rails test                       # 162 model + controller + integration tests
bundle exec rubocop                  # clean

cd e2e && npm install && npx playwright install chromium
npm test                             # 14 Playwright browser tests vs a booted server
```

The Ruby suite covers models, controllers, and integration flows across all six
apps. The Playwright suite (see [`e2e/README.md`](e2e/README.md)) drives real
Chromium against a booted server to prove the things unit tests can't — **cross-tab**
Turbo Stream broadcasts (chat + Kanban morph), optimistic-vote persistence,
debounced frames, ⌘K, per-field validation, streamed deploy progress, and the
`data-turbo-permanent` player surviving navigation.

See [`CODE-REVIEW.md`](CODE-REVIEW.md) for an architecture review and findings.

## Project map

```
app/models/         project, column, issue, comment, member, activity, signup, channel, message
                    ballot/{room,poll,option,question}, pulse/{service,incident},
                    grid/{sheet,row}, spindle/{album,track}
app/controllers/    one per app, namespaced (ballot/, pulse/, grid/, spindle/)
app/channels/       presence_channel.rb, typing_channel.rb   (raw cable; nothing persisted)
app/jobs/pulse/     deploy_job.rb, sample_job.rb             (Active Job → Turbo Stream)
app/lib/showcase.rb the app registry — one row per product; the themeable shell reads it
app/javascript/controllers/   20 Stimulus controllers (sortable, synth, command_palette, …)
blog/               one HTML technical write-up per app
e2e/                Playwright suite (own package.json; touches nothing in app/)
test/               162 minitest tests
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
