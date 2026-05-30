# Code review — Levelbrook Hotwire Showcase

A review of the six-app Hotwire showcase (`Workspace`, `Cadence`, `Pulse`,
`Ballot`, `Grid`, `Spindle`) on Rails 8.1.3 / Ruby 3.3.7. Scope: code quality,
correctness, idiom, test coverage, and end-to-end behaviour.

## Verdict

This is **strong, idiomatic Rails 8 + Hotwire**. It reads like work by someone
who actually understands the framework rather than someone gluing a SPA onto an
API. The patterns are deliberately varied and each is the *correct* tool for its
job — DOM-over-the-wire where content is persisted, raw Action Cable where state
is ephemeral, optimistic UI reconciled by a morph where latency would otherwise
show. RuboCop is clean (0 offenses after a cosmetic autocorrect). One real
staleness bug was found and fixed; everything else is either already correct or a
known demo-scope trade-off.

### What's notably good

- **The "model is the broadcast source of truth" discipline.** Controllers stay
  thin (`head :no_content` / a small partial), and the realtime fan-out lives in
  the model via `broadcasts_refreshes` (Project, Room, Sheet) or
  `after_*_commit` (`Message`, `Comment`). UI updates ride the broadcast, not the
  response. This is exactly how Turbo 8 is meant to be used.
- **Right primitive per job.** `Message#after_create_commit broadcast_append_to`
  for new messages (append), `broadcast_replace_to` for a reaction (surgical
  replace), `broadcasts_refreshes` morph for the Kanban board / poll tallies /
  spreadsheet formula cells (whole-view reconcile), and **raw cable JSON** for
  presence + typing because nothing is persisted. The contrast is intentional and
  well-commented.
- **Drag state is DOM-resident**, so the morph never fights SortableJS — the one
  subtlety that breaks naïve implementations is explicitly handled
  (`sortable_controller.js`, and the `reorder` clamp in `Issues::PositionsController`).
- **`next_issue_number` uses `with_lock`** to make per-project issue numbering
  race-safe. Small detail, correct instinct.
- **Server owns derived data.** Grid formula cells (`Row#total`, `Sheet#grand_total`)
  and Pulse sparklines (`PulseHelper#sparkline`) are computed in Ruby and morphed
  out — no client formula engine, no charting library. Auditable and testable.
- **Allowlists guard dynamic dispatch**: `Issue::FIELDS` / `permitted_field`
  (raises on an unknown field — no partial-path traversal), `Row::EDITABLE` /
  `NUMERIC`. Good security hygiene for "edit any field" endpoints.
- **The themeable shell**: one CSS custom property (`--color-accent`) re-skins six
  products from a single `Showcase` registry row. Adding an app is one data row
  plus its controllers/views.

## Findings

### 1. FIXED — Activity feed served a stale, process-lifetime cache

`Activity.all` memoized at class level (`@all ||= build...`). In a long-running
process the synthetic feed was built **once** and never rebuilt except on a
manual `Activity.reset!` (only called from the seeders). Consequence: new chat
messages, comments, and issue moves never appeared in `/activities` or the
dashboard's "recent activity" until the process restarted or a board was reset —
a real, user-visible staleness bug, and a thread-safety smell (shared mutable
class state under a threaded Puma).

**Fix applied:** `Activity.all` now rebuilds on every read (the source tables are
tiny, so it's a handful of cheap queries). `ActivitiesController#index` builds the
feed **once per request** and slices locally instead of calling `page` + `total`
(which would each rebuild). `reset!` is kept as a documented no-op so existing
callers/tests stay valid. The model test that asserted the *buggy* "stale until
reset" behaviour was rewritten as a regression test proving freshness.

For a high-traffic feed the right production move is a cache keyed on
`max(updated_at)` of the source tables — noted in the code comment.

### 2. KEEP AS-IS (documented fragility) — `increment!` bypasses `touch: true`

`Ballot::VotesController` / `UpvotesController` call `option.increment!(:votes_count)`
(or `question.increment!`) and then **explicitly** `room.touch`. That explicit
touch is **load-bearing**: `ActiveRecord#increment!` writes via a bare UPDATE and
does **not** fire the `belongs_to ..., touch: true` cascade, so it is the *only*
thing that triggers the room's `broadcasts_refreshes` morph after a vote. The code
is correct; the risk is a future "simplification" that deletes the `room.touch`
line assuming the association would cascade — which would silently break live
tallies. This is now covered by tests and called out here. (Surfaced while writing
the new Ballot tests.)

### 3. Minor / demo-scope notes (no change recommended for a showcase)

- **`SearchController` LIKE wildcards aren't escaped.** The query is parameterised
  (no SQL injection), but a user-supplied `%` / `_` is treated as a LIKE
  metacharacter. Harmless for a demo; in production sanitize with
  `sanitize_sql_like`.
- **`Pulse::DeployJob` / `SampleJob` use `sleep`** to pace the streamed progress.
  Fine and intentional for the demo (and it runs in-Puma), but a sleeping job
  holds a worker — in production you'd schedule successive ticks instead.
- **Single demo identity.** `current_member` resolves every browser to
  `Member.order(:id).first` via a shared cookie, so presence/typing across two
  tabs of the *same* browser show one identity. That's an inherent demo
  simplification (cookie-scoped, not tab-scoped), not a bug; worth a one-line note
  on the chat page if it ever reads as "presence is broken."
- **Vote-once is client-trust only** (`localStorage`). Correct to keep for a demo,
  but the blog post and any client-facing framing should be honest that real vote
  integrity needs server-side identity/dedup. (The Ballot post says exactly this.)
- **`Pulse::DashboardController#recent_events`** uses `flat_map { [ ... ] }`
  returning single-element arrays where `map` would do. Cosmetic.

## Test coverage

- **Before:** 102 runs / 299 assertions (models + controllers for Workspace and
  Cadence only; the four namespaced apps had **none**).
- **After:** **162 runs / 413 assertions, 0 failures** — added model tests for
  Ballot/Pulse/Grid/Spindle (share math, formula totals, JSON sample windows,
  `play_payload` parsing, ordering, validations), a `PulseHelper#sparkline` unit
  test (empty/flat/normal series), controller smoke + behaviour tests, and the
  Activity-freshness regression test.
- **End-to-end (new):** a Playwright suite in `e2e/` drives real Chromium against
  a booted server to cover the things Ruby tests can't — ⌘K, debounced frames,
  per-field validation, **cross-tab** `broadcast_append_to`, optimistic-vote
  persistence, SortableJS drag persistence + cross-tab morph, and the
  `data-turbo-permanent` player surviving navigation. See `e2e/README.md`.

## Housekeeping done

- RuboCop: autocorrected 8 cosmetic layout offenses → **0 offenses**.
- `README.md` rewritten — it still described an older two-demo (`/board`, `/story`)
  version that no longer matches the six-app showcase. (Flagged independently by
  every documentation pass.)
- Per-app technical blog posts written to `blog/` (one HTML doc per app).
