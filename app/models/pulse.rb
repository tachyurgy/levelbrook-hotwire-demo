# Pulse — a live ops / incident dashboard in the New Relic mold. The board is
# ALWAYS streaming: a self-perpetuating Active Job (Pulse::TickJob) jitters every
# service ~every 1.8s and broadcasts *targeted* Turbo Stream replaces for the
# golden-signals chart, the KPI tiles, the service grid and the event feed — so
# new samples appear over the wire the instant they're produced, no click, no
# polling, no charting library (server-rendered SVG). table_name_prefix -> pulse_.
module Pulse
  STREAM        = "pulse_dashboard".freeze
  GEN_KEY       = "pulse:generation".freeze
  BEAT_KEY      = "pulse:last_beat".freeze
  TIMELINE_KEY  = "pulse:timeline".freeze
  EVENTS_KEY    = "pulse:events".freeze

  TICK          = 1.8     # seconds between samples
  BEAT_TTL      = 6.0     # if no heartbeat within this window, the ticker is dead
  WINDOW        = 60      # points kept in the rolling timeline
  EVENT_LOG     = 40      # events kept in the rolling feed

  def self.table_name_prefix = "pulse_"

  # ---- Liveness / the always-on ticker ----------------------------------

  # True while a tick chain has produced a heartbeat recently.
  def self.live?
    beat = Rails.cache.read(BEAT_KEY)
    beat.present? && (now - beat) < BEAT_TTL
  end

  def self.current_generation = Rails.cache.read(GEN_KEY)

  # Idempotently make sure exactly one tick chain is running. Called on every
  # dashboard load so the board is already moving on first paint and self-heals
  # after a deploy/restart. The generation guard means if two visitors race to
  # start it, only the newest chain survives (older ones see a stale gen and stop).
  def self.ensure_live!
    return current_generation if live?

    gen = SecureRandom.hex(6)
    Rails.cache.write(GEN_KEY, gen)
    Rails.cache.write(BEAT_KEY, now)          # claim liveness so racers back off
    Pulse::TickJob.perform_later(gen)
    gen
  end

  # ---- One sample tick --------------------------------------------------

  def self.tick!
    Pulse::Service.where.not(status: %w[down deploying]).find_each do |s|
      base = s.latency_ms.clamp(40, 600)
      s.latency_ms = (base + rand(-1.0..1.0) * base * 0.22).round.clamp(28, 820)
      s.error_rate = (s.error_rate + rand(-0.4..0.5)).clamp(0.0, 9.0).round(1)
      s.throughput = (s.throughput + rand(-220..260)).clamp(80, 6500)
      s.status     = s.error_rate > 3 || s.latency_ms > 420 ? "degraded" : "healthy"
      s.push_sample(s.latency_ms)
      s.save!
    end

    record_timeline!
    record_events!
    broadcast_all
  end

  # ---- Rolling system-wide timeline (the golden-signals chart) ----------

  def self.timeline
    Rails.cache.read(TIMELINE_KEY) || seed_timeline
  end

  def self.record_timeline!
    points = (timeline + [ current_point ]).last(WINDOW)
    Rails.cache.write(TIMELINE_KEY, points)
    points
  end

  def self.current_point
    svcs = Pulse::Service.all.to_a
    up   = svcs.reject { |s| s.status == "down" }
    {
      tp:    svcs.sum(&:throughput),
      lat:   up.any? ? (up.sum(&:latency_ms) / up.size) : 0,
      err:   (svcs.map(&:error_rate).max || 0).round(1),
      apdex: apdex(up),
      at:    now
    }
  end

  # Apdex from latency + error rate so the number looks (and moves) like the
  # real thing: 1.0 = everyone satisfied, falls as latency/errors climb.
  def self.apdex(up)
    return 1.0 if up.empty?

    scores = up.map do |s|
      (1.0 - [ s.latency_ms - 90, 0 ].max / 700.0 - s.error_rate / 25.0).clamp(0.0, 1.0)
    end
    (scores.sum / scores.size).round(2)
  end

  def self.seed_timeline
    base_tp = 10_000
    (0...WINDOW).map do |i|
      wobble = Math.sin(i / 6.0) + Math.sin(i / 2.3) * 0.4
      {
        tp:    (base_tp + wobble * 1400 + (i % 7 - 3) * 180).round,
        lat:   (120 + Math.sin(i / 4.0) * 30 + (i % 5 - 2) * 6).round,
        err:   (0.4 + Math.sin(i / 3.0).abs * 0.9).round(1),
        apdex: (0.94 - Math.sin(i / 5.0).abs * 0.06).round(2),
        at:    now - (WINDOW - i) * TICK
      }
    end
  end

  # ---- Rolling event feed (transaction traces / errors / deploys) -------

  def self.events
    Rails.cache.read(EVENTS_KEY) || seed_events
  end

  def self.record_events!
    fresh = synth_events
    Rails.cache.write(EVENTS_KEY, (fresh + events).first(EVENT_LOG))
  end

  ROUTES = {
    "API Gateway"   => [ "GET /v1/graphql", "POST /v1/auth", "GET /v1/health" ],
    "Checkout"      => [ "POST /checkout", "POST /checkout/confirm", "GET /cart" ],
    "Search"        => [ "GET /search", "GET /suggest", "GET /search/facets" ],
    "Notifications" => [ "POST /notify", "GET /inbox", "POST /push" ],
    "Billing"       => [ "POST /charge", "POST /webhooks/stripe", "GET /invoices" ]
  }.freeze

  def self.synth_events
    svcs = Pulse::Service.all.to_a
    return [] if svcs.empty?

    # 1–2 events per tick, biased toward unhealthy services.
    Array.new(rand(1..2)) do
      s = svcs.sample
      route = (ROUTES[s.name] || [ "GET /" ]).sample
      if s.status == "down"
        { at: now, level: "error", service: s.name, text: "#{route} · 503 · circuit open · upstream unreachable" }
      elsif s.error_rate > 3 || rand < (s.error_rate / 30.0)
        code = [ 500, 502, 504 ].sample
        { at: now, level: "error", service: s.name, text: "#{route} · #{code} · #{s.latency_ms}ms · upstream timeout" }
      elsif s.latency_ms > 380
        { at: now, level: "warn", service: s.name, text: "#{route} · slow txn · #{s.latency_ms}ms (p95 breach)" }
      else
        { at: now, level: "info", service: s.name, text: "#{route} · 200 · #{s.latency_ms}ms · #{s.throughput} rpm" }
      end
    end
  end

  def self.seed_events
    Pulse::Service.order(updated_at: :desc).first(8).map.with_index do |s, i|
      route = (ROUTES[s.name] || [ "GET /" ]).sample
      { at: now - i * TICK, level: "info", service: s.name, text: "#{route} · 200 · #{s.latency_ms}ms · #{s.throughput} rpm" }
    end
  end

  # ---- Broadcasts -------------------------------------------------------

  def self.broadcast_all
    broadcast_metrics
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "pulse_services",
      partial: "pulse/dashboard/services",
      locals: { services: Pulse::Service.order(:position).to_a }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "pulse_events",
      partial: "pulse/dashboard/events_feed",
      locals: { events: events.first(14) }
    )
  end

  def self.broadcast_metrics
    Turbo::StreamsChannel.broadcast_replace_to(
      STREAM, target: "pulse_metrics",
      partial: "pulse/dashboard/metrics",
      locals: metrics_locals
    )
  end

  def self.metrics_locals
    {
      services:       Pulse::Service.order(:position).to_a,
      timeline:       timeline,
      open_incidents: Pulse::Incident.where.not(status: "resolved").count
    }
  end

  def self.now = Time.current.to_f

  # ---- Seed -------------------------------------------------------------

  def self.seed!
    return if Service.exists?

    Service.create!([
      { name: "API Gateway",   slug: "api-gateway",   status: "healthy",  latency_ms: 74,  error_rate: 0.1, throughput: 4200, position: 0, samples: jitter(74).to_json },
      { name: "Checkout",      slug: "checkout",      status: "degraded", latency_ms: 240, error_rate: 1.8, throughput: 1800, position: 1, samples: jitter(240).to_json },
      { name: "Search",        slug: "search",        status: "healthy",  latency_ms: 110, error_rate: 0.3, throughput: 3100, position: 2, samples: jitter(110).to_json },
      { name: "Notifications", slug: "notifications", status: "healthy",  latency_ms: 60,  error_rate: 0.2, throughput: 900,  position: 3, samples: jitter(60).to_json },
      { name: "Billing",       slug: "billing",       status: "down",     latency_ms: 0,   error_rate: 100.0, throughput: 0,  position: 4, samples: jitter(180).to_json }
    ])

    checkout = Service.find_by(slug: "checkout")
    billing  = Service.find_by(slug: "billing")
    Incident.create!([
      { service: billing,  title: "Billing webhook timeouts (provider outage)", severity: "sev1", status: "open", started_at: 22.minutes.ago },
      { service: checkout, title: "Elevated p95 latency on /checkout",          severity: "sev2", status: "ack", started_at: 1.hour.ago }
    ])
  end

  # A plausible-looking series of recent latency samples around a baseline.
  def self.jitter(base, count = 24)
    (1..count).map { |i| [ (base + Math.sin(i / 2.0) * base * 0.18 + (i % 5 - 2) * base * 0.05).round, 1 ].max }
  end
end
