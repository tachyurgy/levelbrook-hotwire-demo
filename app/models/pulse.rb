# Pulse — a live ops / incident dashboard. Server-rendered SVG sparklines that
# morph as new samples arrive, a deploy job that streams a progress bar, and
# incidents you acknowledge/resolve. table_name_prefix -> pulse_services etc.
module Pulse
  STREAM = "pulse_dashboard".freeze

  def self.table_name_prefix = "pulse_"

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
