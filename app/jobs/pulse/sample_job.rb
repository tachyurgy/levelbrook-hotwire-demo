# Simulates a burst of live traffic: jitters each service's metrics over a few
# ticks and broadcasts a refresh after each, so every connected dashboard morphs
# its sparklines and status pills in real time — server-rendered, no charting JS,
# no client polling.
class Pulse::SampleJob < ApplicationJob
  queue_as :default

  def perform(ticks = 6)
    ticks.times do
      Pulse::Service.where.not(status: "down").find_each do |service|
        base = service.latency_ms.clamp(40, 600)
        service.latency_ms = (base + (rand(-1.0..1.0) * base * 0.25)).round.clamp(30, 800)
        service.error_rate = (service.error_rate + rand(-0.3..0.5)).clamp(0.0, 8.0).round(1)
        service.throughput = (service.throughput + rand(-200..250)).clamp(100, 6000)
        service.status = service.error_rate > 3 || service.latency_ms > 400 ? "degraded" : "healthy"
        service.push_sample(service.latency_ms)
        service.save!
      end
      Turbo::StreamsChannel.broadcast_refresh_to(Pulse::STREAM)
      sleep 0.6
    end
  end
end
