# The portfolio registry. Each entry is one self-contained Hotwire app mounted
# inside this single Rails 8 codebase. The gallery (root "/") renders a card per
# app; the themeable shell re-skins the chrome by overriding --color-accent with
# the app's accent pair and rendering that app's nav. Adding an app = one row
# here plus its controllers/views — the shell needs no changes.
module Showcase
  App = Data.define(
    :key, :name, :tagline, :domain, :accent, :accent_soft, :glyph, :primitives, :repos
  )

  APPS = [
    App.new(
      key: :workspace, name: "Workspace",
      tagline: "Delivery board for shipping software",
      domain: "Project delivery", accent: "#c8402f", accent_soft: "#f5e3df", glyph: "L",
      primitives: ["SortableJS drag", "broadcasts_refreshes morph", "Turbo Frame drawer", "instant inline edit"],
      repos: %w[rails-trello-clone fizzy ultimate_turbo_modal]
    ),
    App.new(
      key: :cadence, name: "Cadence",
      tagline: "Realtime team chat with presence",
      domain: "Team comms", accent: "#0d9488", accent_soft: "#d3efeb", glyph: "C",
      primitives: ["broadcast_append_to", "Action Cable presence", "typing indicator", "optimistic reactions"],
      repos: %w[once-campfire hotwire-chat hotwire-rails-demo-chat]
    ),
    App.new(
      key: :pulse, name: "Pulse",
      tagline: "Live ops & incident dashboard",
      domain: "Monitoring", accent: "#4f46e5", accent_soft: "#e1dffb", glyph: "P",
      primitives: ["broadcasts_refreshes morph", "Active Job → Turbo Stream", "lazy frames", "View Transitions"],
      repos: %w[turbo-rails turbo-music-drive turbo_power]
    ),
    App.new(
      key: :ballot, name: "Ballot",
      tagline: "Live polls & audience Q&A",
      domain: "Events", accent: "#d97706", accent_soft: "#fbebd0", glyph: "B",
      primitives: ["optimistic UI", "broadcast morph tallies", "CSS-bar charts", "no charting JS"],
      repos: %w[optimistic-ui-hotwire turbo-rails]
    ),
    App.new(
      key: :grid, name: "Grid",
      tagline: "Spreadsheet with live formulas",
      domain: "Data", accent: "#059669", accent_soft: "#d2efe3", glyph: "G",
      primitives: ["frame-scoped cell edit", "server formula recalc", "filter/sort frame", "morph"],
      repos: %w[hottable modern-datatables]
    ),
    App.new(
      key: :spindle, name: "Spindle",
      tagline: "A player that keeps going as you browse",
      domain: "Media", accent: "#7c3aed", accent_soft: "#e8dcfb", glyph: "S",
      primitives: ["data-turbo-permanent", "View Transitions", "lazy track lists", "Web Audio"],
      repos: %w[botcasts turbo-music-drive]
    )
  ].freeze

  def self.all = APPS

  def self.find(key)
    APPS.find { |app| app.key == key.to_sym }
  end
end
