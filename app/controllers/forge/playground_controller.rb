# Forge — interactive playgrounds that dogfood Levelbrook's open-source gems in
# production. Each "Run" is real server-side computation by the vendored gem, so
# the page is itself proof the library works. The results panel is a Turbo Frame
# whose inputs are debounced, so it recomputes live as you type — zero custom JS
# beyond the shared `debounce` controller.
class Forge::PlaygroundController < ApplicationController
  # Frame requests (the debounced live updates) render only the frame, no shell.
  layout -> { turbo_frame_request? ? false : "application" }

  DEFAULT_PATHS = <<~PATHS.freeze
    app/models/user.rb
    app/controllers/relay/messages_controller.rb
    app/views/relay/chat/index.html.erb
    config/routes.rb
    lib/tasks/deploy.rake
    spec/models/user_spec.rb
    README.md
    vendor/gems/picoglob/lib/picoglob.rb
    log/production.log
    .github/workflows/ci.yml
  PATHS

  DEFAULT_CANDIDATES = <<~CANDS.freeze
    app/controllers/application_controller.rb
    app/controllers/relay/messages_controller.rb
    app/models/concerns/searchable.rb
    config/initializers/assets.rb
    config/database.yml
    db/migrate/20260101_create_users.rb
    spec/system/checkout_flow_spec.rb
    lib/ai_stream/writer.rb
    app/javascript/controllers/ai_stream_controller.js
    Gemfile.lock
  CANDS

  # Forge's front door opens on the picoglob bench.
  def index
    redirect_to forge_picoglob_path
  end

  # --- picoglob: bash-style glob -> Ruby Regexp --------------------------
  def picoglob
    @pattern = params[:pattern] || "app/**/*.rb"
    @subject = params[:subject] || DEFAULT_PATHS
    @paths   = lines(@subject, limit: 40)

    begin
      @regexp  = Picoglob.to_regexp(@pattern.to_s)
      @results = @paths.map { |p| [ p, @regexp.match?(p) ] }
      @error   = nil
    rescue StandardError => e
      @error   = e.message
      @regexp  = nil
      @results = @paths.map { |p| [ p, false ] }
    end
    @match_count = @results.count { |_, hit| hit }
  end

  # --- fzy_score: fuzzy match scoring + matched positions ----------------
  def fzy
    @query   = params[:query] || "rmc"
    @subject = params[:subject] || DEFAULT_CANDIDATES
    @candidates = lines(@subject, limit: 60)

    @query = @query.to_s
    if @query.strip.empty?
      @ranked = @candidates.map { |c| [ c, nil, [] ] }
    else
      # [candidate, score, positions], best first, non-matches dropped.
      @ranked = FzyScore.filter(@query, @candidates, positions: true)
    end
    @match_count = @ranked.count { |_, score, _| !score.nil? }
  end

  private

  def lines(text, limit:)
    text.to_s.split("\n").map(&:strip).reject(&:blank?).first(limit)
  end
end
