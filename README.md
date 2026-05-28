# Levelbrook Hotwire Demos

Two production-grade demos of what **Hotwire (Turbo + Stimulus)** does that most people
assume requires a SPA framework — built into one Rails 8 app behind a landing page.

> Built by **Levelbrook Consulting** — senior Rails & Hotwire. · `levelbrookteam@gmail.com`

| | |
|---|---|
| **Stack** | Rails 8.1 · Hotwire (turbo-rails + stimulus-rails) · **importmap** (no Node, no bundler) |
| **Data / realtime** | SQLite · **Solid Queue** · **Solid Cable** · **Solid Cache** — zero external services |
| **Assets** | Propshaft · Tailwind v4 via `tailwindcss-rails` (no PostCSS/Node toolchain) |
| **Deploy** | Kamal 2 to a single Hetzner box · Dockerfile is the Rails 8 default |

```
/         Landing page — frames both demos
/board    Demo 1 — Collaborative Kanban (multiplayer)
/stories  Demo 2 — Choose-Your-Path Story Engine (cinematic)
```

---

## Running locally

```bash
bin/setup            # installs gems, prepares DBs, seeds
bin/dev              # boots Puma (+ Solid Queue in-process) and Tailwind watch
# open http://localhost:3000
```

If you prefer manual steps:

```bash
bundle install
bin/rails db:prepare        # creates + seeds primary, cache, queue, cable DBs
SOLID_QUEUE_IN_PUMA=1 bin/rails server
```

Development uses the **same multi-database setup as production** (`primary`, `cache`,
`queue`, `cable`), with Solid Cable for Action Cable and Solid Queue running inside Puma —
so the realtime and background-job paths you see locally are the ones that ship.

Run the tests:

```bash
bin/rails test       # 24 tests, all green (model + integration)
```

---

## Demo 1 — Collaborative Kanban (`/board`)

A shared, real-time board. Drag a card between columns and **every connected browser
re-settles to match**. The page embeds a second `<iframe>` of the same board beside it, so
a single visitor watches the realtime morph happen in one window.

### Hotwire techniques on display

- **`broadcasts_refreshes` + Turbo 8 morphing (the Fizzy default).**
  `Board` declares `broadcasts_refreshes` (`app/models/board.rb`). Any commit broadcasts a
  single `<turbo-stream action="refresh">`; each subscribed browser re-fetches the current
  page and **morphs** the DOM (idiomorph), preserving scroll and focus. `Column` and `Card`
  use `belongs_to … touch: true`, so moving a card bubbles a touch up to the board and
  triggers the broadcast — **zero hand-written broadcast code**. The whole realtime wiring
  on the page is one line: `<%= turbo_stream_from @board %>`.
- **Morph navigation defaults.** The layout sets
  `<meta name="turbo-refresh-method" content="morph">`, `…-scroll" content="preserve">`,
  and `<meta name="view-transition" content="same-origin">`.
- **HTML5 drag-and-drop in a single Stimulus controller** — no SortableJS.
  `drag_and_drop_controller.js` uses `static targets`/`static classes`, moves the card in
  the DOM optimistically for instant feel, computes the new index, and `PATCH`es the move.
  The server renumbers positions in a transaction (`Card#move_to!`) and the refresh
  broadcast reconciles every client — including the one that did the drag.
- **Action Cable presence**, modeled on once-Campfire's `presence_controller.js`.
  Our `presence_controller.js` subscribes on `connect` and **tears the subscription down on
  `disconnect`** (the #1 Hotwire leak). `PresenceChannel` keeps a per-board connection count
  and broadcasts the rendered "N viewers" badge.
- **Public-demo safety valve.** A "Reset board" button restores the seeded state via the
  shared `BoardSeeder`, so visitors can't permanently wreck the shared board.

---

## Demo 2 — Choose-Your-Path Story Engine (`/story`)

A branching interactive narrative — *"The Last Signal"*, a 16-scene story with 5 endings.
Each choice navigates to the next scene with a cinematic transition; an ambient-audio bar
plays continuously across scenes; and a live tally shows what other readers chose.

### Hotwire techniques on display

- **View Transitions on every choice.** Choices are plain `form` POSTs; the controller
  redirects to the target scene, and because Turbo Drive renders the morph wrapped in
  `document.startViewTransition` (enabled by the `view-transition` meta), scenes cross-fade.
  The scene wrapper carries `view-transition-name: scene`. Degrades silently on browsers
  without the API.
- **A persistent element that never reloads.** The bottom ambient-audio bar is marked
  `id="ambient-bar" data-turbo-permanent`, so Turbo carries the *same* DOM node across every
  scene navigation. `ambient_audio_controller.js` generates a soft drone with the Web Audio
  API (no asset to ship) — the sound and the controller's play state survive each morph,
  which is exactly why keeping state on a *permanent* element is safe here.
- **A live tally via explicit Turbo Stream broadcast.** When any reader picks a branch,
  `Choice#record_pick!` increments the count and `broadcast_replace_later_to` (off the
  request thread, via Solid Queue) replaces only the small tally fragment for everyone
  reading that scene — no one is navigated off their page. This is the deliberate
  counterpoint to the Kanban: a single small fragment changes, so an explicit `replace`
  beats a full-page refresh.
- **Progressive enhancement.** With JavaScript disabled the entire story still works: every
  choice is a real `<form>`, every scene is a real URL, the tally still renders
  server-side. JS just makes it cinematic.

---

## Why this pairing

The two demos cover the two things Hotwire skeptics assume it can't do — **gritty
multiplayer correctness** and **design polish** — while sharing one stack: a single Rails
app, one Solid Cable setup, one deploy. They also showcase both realtime strategies side by
side: `broadcasts_refreshes` + morph for the complex board, explicit `broadcast_replace` for
the surgical tally.

---

## Project map

```
app/models/        board.rb, column.rb, card.rb, story.rb, scene.rb, choice.rb
app/controllers/   pages, boards, cards, stories, scenes, choices
app/channels/      presence_channel.rb
app/services/      board_seeder.rb, story_seeder.rb   (seed + reset, single source of truth)
app/javascript/controllers/
                   drag_and_drop_controller.js, presence_controller.js, ambient_audio_controller.js
test/              models/ + integration/ (24 tests)
```

---

## Deploy (Kamal 2 → one Hetzner box)

Everything is configured in `config/deploy.yml`. The Dockerfile is the Rails 8 default
(Thruster in front of Puma for TLS termination, gzip, and asset caching).

**Before the first deploy, fill in the TODOs in `config/deploy.yml`:**

1. `registry.server` + `registry.username` — the container registry (e.g. `ghcr.io` and your user).
2. `image` — set to `<registry-user>/levelbrook_hotwire_demo`.
3. (Optional) Uncomment the `proxy:` block and set `host:` to your domain for auto Let's
   Encrypt SSL, **and** uncomment `config.assume_ssl` / `config.force_ssl` in
   `config/environments/production.rb`. Point a DNS A record at `5.78.108.109`.

The server IP is already set to `5.78.108.109`. SQLite + Solid Queue/Cable/Cache all run on
the single box (a persistent volume `…_storage` holds the SQLite files) — no database or
Redis accessory needed.

### Exact commands to deploy

```bash
# 1. One-time: registry login token in your shell
export KAMAL_REGISTRY_PASSWORD=<your registry token>

# 2. First-ever deploy to a fresh server (installs Docker + kamal-proxy, then deploys):
bin/kamal setup

# 3. Every subsequent deploy:
bin/kamal deploy

# 4. Seed the demos once (board + story) on the server:
bin/kamal app exec "bin/rails db:seed"
```

Building an `amd64` image from an Apple-silicon (arm64) Mac: either let Docker buildx
emulate (slower), or set a remote `builder.remote:` in `config/deploy.yml` pointing at an
amd64 Docker host for fast native builds.

Useful afterwards:

```bash
bin/kamal logs -f          # tail app logs
bin/kamal console          # rails console on the server
```
