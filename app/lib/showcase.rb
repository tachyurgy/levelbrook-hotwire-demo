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
      primitives: [ "SortableJS drag", "broadcasts_refreshes morph", "Turbo Frame drawer", "instant inline edit" ],
      repos: %w[rails-trello-clone fizzy ultimate_turbo_modal]
    ),
    App.new(
      key: :relay, name: "Relay",
      tagline: "Stream a live LLM into Rails over the AI SDK protocol",
      domain: "AI engineering", accent: "#e11d48", accent_soft: "#fde4e9", glyph: "R",
      primitives: [ "ActionController::Live SSE", "ai_stream protocol encoder", "Gemini token stream", "live tool-call parts" ],
      repos: %w[ai_stream]
    ),
    App.new(
      key: :forge, name: "Forge",
      tagline: "Interactive playground for Levelbrook's open-source gems",
      domain: "Open source", accent: "#0891b2", accent_soft: "#d3edf3", glyph: "F",
      primitives: [ "picoglob glob -> Regexp", "fzy_score fuzzy ranking", "debounced server compute", "matched-position highlight" ],
      repos: %w[picoglob fzy_score]
    )
  ].freeze

  def self.all = APPS

  def self.find(key)
    APPS.find { |app| app.key == key.to_sym }
  end
end
