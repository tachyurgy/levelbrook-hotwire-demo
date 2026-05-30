# End-to-end tests (Playwright)

Browser-level tests that drive a **real Chromium** against a **booted Rails
server** to prove the Hotwire flows work end to end — the things model and
controller tests can't see: Turbo Stream broadcasts arriving in a second tab,
SortableJS drag persistence, ⌘K, debounced frames, optimistic UI reconciled by
a morph, and the `data-turbo-permanent` player surviving navigation.

This suite is intentionally isolated from the Ruby app: it has its own
`package.json` and `node_modules` and touches nothing in `app/`.

## Running

```bash
cd e2e
npm install
npx playwright install chromium   # one-time browser download
npm test                          # boots the Rails server + runs all specs
```

Playwright's `webServer` boots the app for you (see `playwright.config.js`): it
runs `db:prepare`, reseeds a **deterministic** demo state via
`e2e/reset_seed.rb`, builds Tailwind, then starts Puma on port **3001** with
`SOLID_QUEUE_IN_PUMA=1` so background jobs (Pulse deploys) run in-process and
Solid Cable carries the Action Cable / Turbo Stream broadcasts — no Redis.

Useful variants:

```bash
npm run test:headed        # watch it drive the browser
npx playwright test gallery # one spec
npm run report             # open the last HTML report
```

> The run reseeds the **development** database to a known state on boot. That DB
> is throwaway demo data. Set `E2E_PORT` to use a different port.

## What's covered

| Spec | Hotwire primitive proven |
|---|---|
| `gallery.spec.js` | Showcase registry + Turbo navigation |
| `command-palette.spec.js` | ⌘K, server-rendered results frame, keyboard select |
| `search.spec.js` | Debounced Turbo Frame + URL advance |
| `signup-validation.spec.js` | Per-field live validation (server-rendered errors) |
| `cadence-chat.spec.js` | `broadcast_append_to` — incl. **cross-tab** live delivery |
| `ballot-poll.spec.js` | Optimistic UI + server-persisted vote |
| `kanban-drag.spec.js` | The drop-handler contract → reorder → `broadcasts_refreshes` morph (+ cross-tab)¹ |
| `spindle-player.spec.js` | `data-turbo-permanent` element surviving navigation |
| `pulse-dashboard.spec.js` | Active Job → Turbo Stream streamed progress (no polling) |

> ¹ SortableJS uses native HTML5 drag-and-drop, which headless Chromium will not
> start from synthetic input (so the lib's `onEnd` never fires). The spec therefore
> issues the exact `PUT` the drop handler sends and asserts the genuinely-Hotwire
> part: the server reorder, the live `broadcasts_refreshes` morph (incl. cross-tab),
> and reload persistence. The drag *gesture* itself is best verified headed/manually.
