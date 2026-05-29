# Streams a deploy's progress to the dashboard. Demonstrates the
# background-job -> Turbo Stream loop: the job broadcast_replaces a progress
# partial at intervals (no polling), then flips the service healthy and
# broadcasts a refresh so the morph reconciles the whole board.
class Pulse::DeployJob < ApplicationJob
  queue_as :default

  STEPS = [ 6, 18, 33, 49, 64, 78, 91, 100 ].freeze

  def perform(service_id)
    service = Pulse::Service.find(service_id)
    service.update!(status: "deploying")
    Turbo::StreamsChannel.broadcast_refresh_to(Pulse::STREAM)

    STEPS.each do |pct|
      broadcast_progress(service, pct)
      sleep 0.45
    end

    service.update!(
      status: "healthy",
      latency_ms: [ (service.latency_ms * 0.7).round, 40 ].max,
      error_rate: 0.2
    )
    broadcast_progress(service, 100, done: true)
    Turbo::StreamsChannel.broadcast_refresh_to(Pulse::STREAM)
  end

  private

  def broadcast_progress(service, pct, done: false)
    Turbo::StreamsChannel.broadcast_replace_to(
      Pulse::STREAM,
      target: "deploy_status",
      partial: "pulse/dashboard/deploy_status",
      locals: { service: service, pct: pct, done: done, active: !done }
    )
  end
end
