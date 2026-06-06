# Comprehensive Hotwire Showcase Review

Date: 2026-05-30
Repo reviewed: `/Users/magnusfremont/Desktop/levelbrook-hotwire-demo`

## Scope

This review covers the six-app Levelbrook Hotwire Showcase:

- Workspace: Kanban, inline editing, command palette, live search, lazy drawer, activity feed.
- Cadence: realtime chat, presence, typing, reactions.
- Pulse: live ops dashboard, background job progress, incidents.
- Ballot: live polls and Q&A.
- Grid: spreadsheet-style editing and server-computed formulas.
- Spindle: persistent music player with Web Audio.

I also did a quick inventory of nearby Hotwire/Rails projects under `_projects`.
`_projects/inline-crm` and `_projects/stock-watchlist` are separate Hotwire apps,
but this report treats `levelbrook-hotwire-demo` as the portfolio showcase because
it is the repo with the gallery front door, six integrated demos, blog write-ups,
and current verification suite. If those older apps are meant to be part of the
same hiring portfolio, they should be linked as secondary case studies rather
than merged into this review.

## Verification Performed

Commands run from `levelbrook-hotwire-demo`:

```bash
bin/rails test
bundle exec rubocop
bundle exec brakeman -q
cd e2e && npm test
```

Results:

- Rails test suite: 162 runs, 413 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop: 121 files inspected, no offenses detected.
- Brakeman: 0 security warnings.
- Playwright: 14 browser specs passed against a booted Rails server.

The Playwright suite verified the important browser-level claims: gallery routing,
command palette, debounced search, signup validation, cross-tab chat broadcasts,
poll voting, Kanban reorder broadcast, persistent Spindle player, and Pulse job
progress streaming.

## Hiring Verdict

Yes, this is an impressive Hotwire portfolio showcase.

It is substantially better than a typical demo app because it shows multiple
production-shaped interaction patterns in one coherent Rails codebase:

- The Rails server stays authoritative for persisted UI.
- Turbo Streams are used for persisted collaboration.
- Raw Action Cable is used for ephemeral state like presence and typing.
- Stimulus owns local interaction state without becoming a client-side app.
- Background jobs, Solid Queue, Solid Cable, importmap, Turbo morphing, and
  server-rendered partials are all represented in working flows.
- The repo has meaningful Ruby tests and real browser tests, not just happy-path
  screenshots.

My hiring read: this would get attention from a Rails/Hotwire hiring manager,
especially for senior Rails consulting, staff augmentation, or product-engineering
work. It communicates good taste and real framework fluency. The strongest signal
is not any one feature; it is that each demo uses a different Hotwire primitive
for the correct reason.

The caveat: it still reads more like an excellent technical showcase than a
fully productized public portfolio. The code quality is strong, but the demo can
be made more persuasive by tightening authenticity, demo resilience, accessibility,
and the "why this matters to your business" framing.

## What Is Already Strong

### 1. The architecture is idiomatic Rails + Hotwire

The showcase avoids the common anti-pattern of using Rails as a JSON backend and
rebuilding UI state in JavaScript. Controllers are mostly thin, persisted state
is modeled in Active Record, and the browser receives server-rendered HTML.

Notable examples:

- `Project.broadcasts_refreshes` gives the Kanban board a clean model-owned
  broadcast source.
- `Message` uses `broadcast_append_to` for new messages and `broadcast_replace_to`
  for reactions, which is the right split between feed growth and surgical update.
- Ballot and Grid lean on morph refreshes where derived totals need to reconcile
  across clients.
- Pulse demonstrates background job to Turbo Stream progress without polling.
- Spindle demonstrates `data-turbo-permanent` for a real reason, not as trivia.

### 2. The demos are varied enough to show range

The six apps cover a good surface area:

- Collaborative boards.
- Realtime chat.
- Live dashboards.
- Optimistic interactions.
- Spreadsheet-style editing.
- Persistent media.

That range matters for hiring because it says "I know the framework deeply enough
to choose among its tools," not merely "I can make a CRUD app."

### 3. The test story is unusually good for a portfolio demo

The Rails tests cover models, controllers, and integration flows. The Playwright
suite covers the flows that unit tests cannot credibly prove: WebSocket delivery,
browser persistence, and Stimulus behavior.

This is one of the strongest parts of the project. It gives the showcase a level
of credibility most portfolio projects do not have.

### 4. The README is direct and useful

The README sets expectations clearly: six real apps, one Rails 8 codebase, zero
SPA. It lists routes, primitives, setup commands, and tests. That helps a reviewer
quickly understand what to look for.

### 5. The code is clean enough to survive scrutiny

RuboCop and Brakeman are clean. The code is readable. Comments mostly explain
Hotwire intent rather than narrating obvious Ruby. The app organization is simple
enough for a reviewer to browse without getting lost.

## Highest Priority Recommendations

These are the changes I would make before treating this as a final public hiring
showcase.

### 1. Add a guided demo mode on the gallery

The app currently says "Pick one and open it." That is fine for a Rails person,
but hiring reviewers skim. Add a short "recommended path" on the gallery:

1. Open Workspace in two windows and drag a card.
2. Open Cadence in two windows and send a message.
3. Run a Pulse deploy and watch streamed progress.
4. Vote in Ballot and reload.
5. Edit a Grid cell and watch totals update.
6. Play Spindle and navigate away.

This should be concise and not turn into marketing fluff. The goal is to make the
best parts impossible to miss.

### 2. Add a public "What to look for" page or modal per app

The technique captions are useful, but they are embedded inside each UI. A
reviewer should be able to understand each app in 30 seconds:

- What interaction to try.
- Which files implement it.
- Which Hotwire primitive it demonstrates.
- What production trade-off is being simplified.

The existing `blog/` pages likely cover this in depth. The missing layer is a
short in-app bridge between "playing with the demo" and "reading a technical
write-up."

### 3. Make demo trade-offs explicit, not hidden

There are several intentionally demo-scoped choices. They are acceptable, but
they should be disclosed so they do not look like accidental omissions:

- Ballot vote-once state is client-trust only through `localStorage`.
- Cadence identity is browser-cookie scoped, not real user auth.
- Pulse deploy jobs use `sleep` to create visible progress.
- Search is simple SQL `LIKE`, not full-text search.
- Workspace drag persistence does not implement authorization.

In a portfolio, honesty improves confidence. A senior reviewer will spot these
anyway; you want them to see that you spotted them first.

### 4. Harden the endpoints that currently trust route/client context

This is a demo, but a hiring reviewer may still inspect controller boundaries.
Several endpoints are intentionally thin and trust client inputs:

- `Grid::CellsController#update` accepts a row id and field, then silently ignores
  unsupported fields through the model. It should return `400` or `422` for an
  invalid field rather than `204`.
- `Issues::PositionsController#update` finds any `Column` by id. A crafted request
  could move an issue into a column from another project. Lock it to
  `issue.project.columns.find(params[:column_id])`.
- `Ballot::VotesController#create` and `Ballot::UpvotesController#create` permit
  unlimited server-side increments. That is fine for an anonymous demo, but
  should be framed as "optimistic interaction demo, not vote integrity."

These fixes are small and would raise the code-review bar.

### 5. Escape SQL LIKE wildcards in search

`SearchController#show` parameterizes the query, so this is not SQL injection.
But `%` and `_` still behave as wildcards:

```ruby
.where("title LIKE :q OR description LIKE :q", q: "%#{@query}%")
```

Use `sanitize_sql_like` before building the pattern. It is a small improvement
and a good signal that you understand the difference between injection safety and
search semantics.

### 6. Add accessibility checks to CI

The UI looks deliberately designed, but the test suite does not appear to include
automated accessibility checks. Add axe checks for the gallery and one page per
app. Focus on:

- Dialog labeling for the command palette.
- Keyboard access for inline edit, polls, and player controls.
- Focus return after modal/drawer close.
- Live regions for chat, typing, deploy progress, and validation errors.
- Sufficient contrast for the per-app accent themes.

This would materially improve the hiring signal because Hotwire apps often fail
on keyboard and focus behavior.

### 7. Add a small "reviewer confidence" badge section

On the gallery or README, show verified facts:

- Rails tests passing.
- Playwright browser suite.
- Brakeman clean.
- RuboCop clean.
- No external Redis required.
- Runs locally with one command.

This should be understated, not decorative. The point is to communicate that the
showcase is not fragile.

### 8. Make the deployed demo reset-safe

The README mentions seed/reset behavior, and individual apps expose reset
buttons. For a public demo, add an obvious "Reset all demo data" action or a
scheduled reset job. Reviewers can leave state dirty, and the next visitor should
not see a broken or confusing dataset.

If you do not want a public reset-all button, run a periodic reseed in production
and document it.

## App-by-App Review

## Workspace

Verdict: strongest app in the showcase.

Why it works:

- Kanban drag plus cross-tab morph is a high-value Hotwire demonstration.
- Inline editing enters edit mode instantly, which avoids the common "Hotwire
  feels laggy" failure mode.
- Command palette and search give it product depth.
- Lazy issue drawer is a good use of Turbo Frames.

Recommendations:

1. Scope dropped columns to the issue's project in `Issues::PositionsController`.
   This prevents cross-project moves from crafted requests.
2. Return a useful error if a drag reorder request is malformed. Right now the
   happy path is clean, but bad ids will raise generic Active Record exceptions.
3. Add explicit tests for cross-project move rejection once fixed.
4. Add a visible "open in another tab" demo cue on the board page.
5. Add keyboard-accessible card movement or document that drag is pointer-only.
6. Add a regression test for `update_column` reorder behavior so future changes
   do not accidentally remove the broadcast-triggering touch path.
7. Consider adding a "new issue" flow. The app proves editing and moving, but a
   reviewer may expect creation in a Jira-like board.
8. Add optimistic drag failure handling in Stimulus: if the PUT fails, display a
   toast and reload or restore the card order.
9. The activity feed rebuilds every request. That is fine for demo data; document
   or implement a cache key based on source table max timestamps if positioning
   this as production-shaped.
10. Make the command palette available outside Workspace or explain why it is a
    Workspace-only primitive.

## Cadence

Verdict: excellent technical contrast to Workspace because it uses raw Cable for
ephemeral state and Turbo Streams for persisted messages.

Why it works:

- `broadcast_append_to` for messages is the correct primitive.
- `broadcast_replace_to` for reactions is the correct primitive.
- Presence and typing do not abuse persisted DOM updates.
- Playwright verifies cross-tab message delivery.

Recommendations:

1. Add a small identity switcher in demo mode. The current browser identity
   chooses the first member and persists it in cookies, so two tabs from the same
   browser look like one person. That is fine technically, but less impressive
   when demoing presence.
2. Presence is keyed by member name in cache. Use member id as the key and render
   names from stored values to avoid collisions.
3. Add an expiry cleanup behavior that broadcasts when a user silently disappears.
   Current pruning happens when presence is touched, so stale names may linger
   until another event.
4. Add a live-region announcement or accessible status for new messages.
5. Add rate limiting or body-length caps for messages/reactions in production
   mode.
6. Add a test for typing events, not just persisted message broadcasts.
7. Consider optimistic message rendering for the sender with reconciliation, if
   you want to show another client-state pattern.
8. Make reaction failure behavior explicit in the Stimulus controller. If the
   POST fails, the optimistic count should be reverted or marked stale.
9. Add "open another window" copy directly in the app, not only in README/tests.
10. Consider showing connection state, especially for a live deployed demo on
    free-tier infrastructure.

## Pulse

Verdict: strong visual demo and good proof that server-rendered dashboards do not
need client charting libraries.

Why it works:

- Active Job streams progress without polling.
- Server-rendered sparkline SVGs are a good Hotwire-friendly alternative to a
  charting stack.
- Incidents and service status give the page a realistic operational shape.

Recommendations:

1. Replace `sleep`-paced progress with scheduled ticks if you want to claim a
   production-ready job pattern. Keep the current version if it is explicitly
   framed as demo pacing.
2. Prevent starting multiple deploys for the same service at the same time, or
   show them as concurrent operations intentionally.
3. Add failure/cancel states for deploys. A progress bar that always succeeds is
   less convincing.
4. Persist deploy records rather than only streaming a transient partial if you
   want auditability.
5. Add tests for incident acknowledge/resolve flows in the browser.
6. Add accessible progress semantics (`role="progressbar"` with values) to the
   deploy widget.
7. Make the lazy events panel more prominent; it is a good Turbo Frame demo but
   easy to miss.
8. Reduce log noise in the E2E web server output if this runs in CI; current
   Solid Queue/Cable logs are verbose.
9. Add a "last updated" timestamp per service so morphing changes are easier to
   see during demos.
10. Document that Solid Queue in Puma is a local/demo deployment choice.

## Ballot

Verdict: good optimistic UI demo, but it needs the clearest trade-off disclosure.

Why it works:

- Client-side optimistic bars make the app feel immediate.
- The server remains authoritative and reconciles with morph broadcasts.
- `localStorage` surviving morphs is a useful Stimulus demonstration.

Recommendations:

1. State clearly in the UI or write-up that vote-once is local demo state, not
   server-enforced vote integrity.
2. Add server-side session or signed-cookie dedupe if you want it to feel more
   production-shaped.
3. Add failure handling in `poll_controller.js`; if the POST fails after the
   optimistic increment, the user currently sees a misleading local result.
4. Add a disabled/loading state while a vote request is in flight.
5. Include `aria-pressed` or equivalent state on selected options.
6. Add a test for double-click/double-submit behavior.
7. Add a test proving an option from another poll cannot be voted through a
   crafted request. The nested lookup looks good, but the test would document it.
8. For Q&A upvotes, decide whether repeated upvotes are a feature or a demo
   shortcut. The server currently permits unlimited increments.
9. Add a visual "your vote" label, not just a ring.
10. Consider adding a moderator action, such as marking a question answered, to
    make Ballot feel like a fuller product.

## Grid

Verdict: technically clean, but currently the lightest app in perceived product
depth.

Why it works:

- Frame-scoped cell editing is a natural Hotwire use case.
- Server-owned formulas are a strong "no client state machine" demonstration.
- Morphing recomputed totals across clients is the correct proof point.

Recommendations:

1. Return an error for invalid cell fields rather than silently ignoring them.
2. Add cross-tab Playwright coverage for formula recomputation if not already
   present in detail.
3. Add keyboard navigation between cells; spreadsheet expectations are keyboard
   heavy.
4. Add a "dirty/saved" microstate so inline edits feel intentional.
5. Preserve focus after a morph if the user is editing adjacent cells.
6. Support decimals for unit price. Stripping all non-digits makes `$12.50` turn
   into `1250`, which may be intentional cents math but should be obvious.
7. Make numeric parsing explicit in the UI: dollars, cents, whole units, etc.
8. Add formula examples beyond row total and grand total if you want this to feel
   less toy-like.
9. Add validation error rendering inside the edited frame.
10. Add a short note explaining why formulas belong on the server.

## Spindle

Verdict: memorable and differentiated. This is the app most likely to make a
reviewer say "I did not expect that in Hotwire."

Why it works:

- Persistent player is a clean, concrete reason for `data-turbo-permanent`.
- Web Audio synthesis avoids asset dependencies.
- Navigation survival is verified in Playwright.

Recommendations:

1. Add visible playback state that survives navigation: current track, elapsed
   time, pause/play, and maybe queue position.
2. Add keyboard-accessible controls for play/pause and next/previous.
3. Add a user gesture fallback/error message for browsers that block audio.
4. Add a mute/volume control.
5. Add reduced-motion consideration for any animated visualizer.
6. Add tests that the player state, not only the DOM element, survives navigation.
7. Add a "why this matters" caption: Turbo can preserve long-lived client objects
   without a SPA router.
8. Make the audio synthesis code easy to inspect from the app/write-up; this is
   a differentiator.
9. Add graceful cleanup when the permanent element is finally disconnected.
10. Consider making Spindle the final step in the guided tour because it is a
    strong closing demo.

## Cross-Cutting Code Recommendations

1. Add request-level guardrails for malformed ids and invalid fields.
2. Add a public demo environment flag so demo shortcuts are explicit in code:
   `demo_mode?`, `DemoIdentity`, `DemoVoteState`, etc.
3. Add a small `DemoReset` service that resets all six apps consistently.
4. Add Playwright accessibility checks with `@axe-core/playwright`.
5. Add mobile viewport Playwright coverage for one representative app plus the
   gallery.
6. Add a CI workflow that runs Rails tests, RuboCop, Brakeman, and Playwright.
7. Add screenshots or short animated clips to README/blog so reviewers understand
   the payoff before running locally.
8. Add line-of-code/file links in blog write-ups to point reviewers at the exact
   implementation.
9. Add a CHANGELOG or "build notes" page showing how the showcase evolved.
10. Add production error monitoring if the deployed demo is public.
11. Consider seeding demo data with more realistic domain text and fewer obvious
    placeholder names.
12. Make all reset buttons visually consistent and place them where a reviewer
    can find them without fear.
13. Add a "known trade-offs" section to the README, separate from "Findings".
14. Add browser support notes because `allow_browser versions: :modern` rejects
    older browsers by design.
15. Add cache invalidation comments/tests for any page that depends on synthetic
    read models, like Activity.
16. Add stricter model validations for enums/statuses where currently only view
    code assumes a finite set.
17. Add request specs for negative paths, not only happy paths.
18. Add concurrency tests for vote increments and drag reorder if you want to
    push the "production-shaped" claim.
19. Avoid relying on hidden prior knowledge in UI copy. Each app should tell the
    reviewer what interaction demonstrates Hotwire.
20. Keep comments focused on surprising framework behavior. Some comments are
    excellent; avoid letting every file become a tutorial.

## Cross-Cutting UX Recommendations

1. Add a guided review path from the gallery.
2. Add one concise "try this" instruction per app.
3. Add a persistent link from each app to its technical write-up.
4. Add a persistent link back to the gallery from every app.
5. Add visible cross-tab prompts for Workspace, Cadence, Pulse, Ballot, and Grid.
6. Add stronger empty/error states for failed network requests.
7. Add more obvious loading states for lazy Turbo Frames.
8. Add focus rings and keyboard paths for all interactive controls.
9. Add accessible labels for icon-only or symbolic controls.
10. Add mobile-specific polish passes. Boards, grids, and dashboards are where
    layout problems usually show first.
11. Make app accents feel branded but not overpowering.
12. Avoid overusing tiny mono text for important instructions; it can read like
    metadata rather than guidance.
13. Make reset actions clearly destructive but safe.
14. Add "last event" or "live" indicators so WebSocket updates are observable.
15. Add graceful offline/reconnect messaging for Cable-backed demos.

## Portfolio Positioning Recommendations

1. Lead with "six production-shaped Hotwire apps" rather than only "zero SPA."
   The "zero SPA" point is good, but the stronger hiring signal is judgement:
   knowing when server-rendered HTML is enough.
2. Add a short paragraph that names the business value: fewer moving parts,
   simpler deployment, shared rendering, testable server logic, and less client
   state.
3. Include a "for Rails teams" CTA if this is meant to sell Levelbrook consulting.
4. Add a "for hiring managers" README section with:
   - what to run,
   - what to inspect,
   - what the tests prove,
   - what trade-offs are intentionally demo-scoped.
5. Avoid overstating "production" where the app intentionally skips auth,
   permissions, rate limits, or durable audit trails. Use "production-shaped"
   consistently.
6. Make the technical blog posts discoverable from the running app, not just the
   repo.
7. Add a short architecture diagram for how Turbo Streams, Solid Cable, and
   browser tabs interact.
8. Add one deployment note that explains why SQLite + Solid stack is a strength
   for this demo.
9. Consider including the older `_projects/inline-crm` and `_projects/stock-watchlist`
   as "additional Hotwire case studies" if they are maintained and verified.
10. Remove or soften phrases that require proof outside the repo, such as "mined
    from 35 studied open-source Hotwire repos," unless the supporting research is
    linked.

## Specific Code Findings And Suggested Fixes

### Search wildcard semantics

File: `app/controllers/search_controller.rb`

Current query uses a parameterized `LIKE`, which is injection-safe, but does not
escape `%` and `_`.

Suggested fix:

```ruby
escaped = ActiveRecord::Base.sanitize_sql_like(@query)
pattern = "%#{escaped}%"
Issue.includes(:assignee, column: :project)
     .where("title LIKE :q OR description LIKE :q", q: pattern)
```

Priority: medium. Small fix, good review signal.

### Kanban column scoping

File: `app/controllers/issues/positions_controller.rb`

Current code finds the destination column globally:

```ruby
column = Column.find(params[:column_id])
```

Suggested fix:

```ruby
column = issue.project.columns.find(params[:column_id])
```

Priority: high for code-review polish. It closes a simple trust-boundary gap.

### Grid invalid field handling

File: `app/controllers/grid/cells_controller.rb`

Current code delegates unsupported fields to `assign_cell`, which silently does
nothing and still returns `204`.

Suggested fix: have the model expose `editable_field?` or raise a domain-specific
exception, then return `400`/`422` for invalid fields.

Priority: medium.

### Ballot vote integrity

Files:

- `app/controllers/ballot/votes_controller.rb`
- `app/controllers/ballot/upvotes_controller.rb`
- `app/javascript/controllers/poll_controller.js`

Current behavior is acceptable for an anonymous optimistic UI demo, but not for a
real vote system. Server-side dedupe would make the demo more credible.

Priority: medium for portfolio polish; high only if claiming production vote
integrity.

### Pulse sleeping job

File: `app/jobs/pulse/deploy_job.rb`

`sleep 0.45` is fine for a visual demo. If this is described as a production job
pattern, replace it with scheduled continuation jobs or a persisted deploy state
machine.

Priority: low if documented; medium if left implicit.

### Presence identity

Files:

- `app/controllers/application_controller.rb`
- `app/channels/presence_channel.rb`

The demo identity is stable and simple, but every new browser defaults to the
first member. Add an identity switcher or random demo identity assignment so
presence feels real during live demos.

Priority: medium, because presence is a headline Cadence feature.

## Should This Get You Hired?

For Rails/Hotwire roles: yes, it should materially improve your odds.

The showcase demonstrates:

- Real Hotwire judgement.
- Rails 8 fluency.
- Server-rendered UI confidence.
- Action Cable competence.
- Background job integration.
- Testing discipline.
- Ability to package technical work into a coherent product narrative.

What could hold it back:

- A reviewer may miss the best interactions without guidance.
- Demo-scoped choices may be mistaken for production oversights if not disclosed.
- Accessibility and keyboard support are not yet visibly proven.
- Some apps, especially Grid and Ballot, could use a little more product depth.
- Older related Hotwire projects appear separate and are not clearly positioned
  relative to the main showcase.

Bottom line: this is already a strong portfolio piece. With the top-priority
polish items above, it can move from "impressive demo repo" to "credible evidence
that this person can lead Hotwire work in a real Rails product."

## Recommended Next Work Order

1. Add guided demo path on the gallery.
2. Add "known trade-offs" to README and per-app write-ups.
3. Fix the small trust-boundary issues: Kanban column scoping, search wildcard
   escaping, Grid invalid field responses.
4. Add server-side vote/session dedupe or clearly label Ballot as client-trust
   optimistic UI.
5. Add demo identity switching for Cadence.
6. Add accessibility checks and keyboard coverage.
7. Add CI workflow running Rails tests, RuboCop, Brakeman, and Playwright.
8. Add in-app links from demos to technical write-ups.
9. Add reset-all or scheduled reseed for public demo durability.
10. Add short clips/screenshots to README/blog for reviewers who will not run the
    app locally.

