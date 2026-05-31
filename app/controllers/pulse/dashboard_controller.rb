class Pulse::DashboardController < ApplicationController
  def index
    Pulse.ensure_live!   # board is already streaming on first paint — no click

    @services       = Pulse::Service.order(:position).to_a
    @timeline       = Pulse.timeline
    @events         = Pulse.events.first(14)
    @incidents      = Pulse::Incident.order(Arel.sql("status = 'resolved', started_at DESC")).to_a
    @open_incidents = @incidents.count { |i| !i.resolved? }
    @services_for_deploy = @services.reject { |s| s.status == "down" }
  end
end
