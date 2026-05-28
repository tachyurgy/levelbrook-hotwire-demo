# Single source of truth for the demo board's starting state. Used by both
# db/seeds.rb and the "Reset board" button so a public visitor can always
# restore a sensible board after dragging things around.
class BoardSeeder
  SLUG = "launch".freeze

  COLUMNS = [
    { name: "Backlog",     accent: "slate" },
    { name: "In Progress", accent: "sky" },
    { name: "Review",      accent: "violet" },
    { name: "Shipped",     accent: "emerald" }
  ].freeze

  CARDS = {
    "Backlog" => [
      { title: "Add View Transitions to checkout flow", assignee: "Priya", tag: "frontend",
        body: "Cross-document VT between cart and confirmation; degrade gracefully on Firefox." },
      { title: "Rate-limit the public API", assignee: "Marcus", tag: "infra",
        body: "Token bucket per API key; return Retry-After. Solid Cache for counters." },
      { title: "Spike: Hotwire Native shell", assignee: "Dana", tag: "research",
        body: "Wrap the existing URLs in a native tab bar; evaluate bridge components." }
    ],
    "In Progress" => [
      { title: "Morph-safe drag and drop", assignee: "Lena", tag: "frontend",
        body: "HTML5 DnD Stimulus controller; persist position, broadcast refresh." },
      { title: "Solid Queue dashboard", assignee: "Marcus", tag: "backend",
        body: "Mission Control mounted at /jobs, basic-auth gated in production." }
    ],
    "Review" => [
      { title: "Presence badge for the board", assignee: "Dana", tag: "realtime",
        body: "Per-board viewer count over Action Cable, à la Campfire presence." }
    ],
    "Shipped" => [
      { title: "broadcasts_refreshes on Board", assignee: "Lena", tag: "realtime",
        body: "Every commit morphs all connected browsers. Zero custom broadcast code." },
      { title: "Tailwind v4 via tailwindcss-rails", assignee: "Priya", tag: "frontend",
        body: "No Node build step; importmap-only JS. Propshaft asset pipeline." }
    ]
  }.freeze

  def self.reset!(board = nil)
    board ||= Board.find_or_initialize_by(slug: SLUG)
    board.update!(
      name: "Launch Board",
      description: "A shared, real-time Kanban board. Drag a card and watch every open browser re-settle."
    )
    board.columns.destroy_all

    COLUMNS.each_with_index do |attrs, ci|
      column = board.columns.create!(attrs.merge(position: ci))
      (CARDS[attrs[:name]] || []).each_with_index do |card_attrs, idx|
        column.cards.create!(card_attrs.merge(position: idx))
      end
    end

    board
  end
end
