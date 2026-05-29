class Pulse::DashboardController < ApplicationController
  def index
    @services = Pulse::Service.order(:position)
    @incidents = Pulse::Incident.order(Arel.sql("status = 'resolved', started_at DESC"))
    @services_for_deploy = @services.reject { |s| s.status == "down" }
  end

  # Lazy-loaded panel (deferred Turbo Frame) — recent synthetic events.
  def panel
    render partial: "pulse/dashboard/panels/events", locals: { events: recent_events }
  end

  # Kick off a burst of simulated traffic; the job streams morphs back.
  def simulate
    Pulse::SampleJob.perform_later
    head :no_content
  end

  private

  def recent_events
    Pulse::Service.order(updated_at: :desc).flat_map do |s|
      [
        { at: s.updated_at, service: s.name, text: "p95 #{s.latency_ms}ms · #{s.error_rate}% err · #{s.throughput} rps" }
      ]
    end.first(12)
  end
end
