class Pulse::IncidentsController < ApplicationController
  include ActionView::RecordIdentifier

  # Acknowledge / resolve. The original bug: this returned `head :no_content` and
  # relied on broadcast_REFRESH — but Turbo SUPPRESSES a refresh in the tab that
  # initiated it (it dedups by request-id), so the clicking tab saw nothing change.
  # Targeted stream actions (replace/prepend) are NOT suppressed, so we broadcast a
  # replace of just this card to every tab — including the one that clicked — and
  # it updates everywhere, instantly.
  def update
    incident = Pulse::Incident.find(params[:id])
    return head :unprocessable_entity unless Pulse::Incident::STATUSES.include?(params[:status])

    incident.update!(status: params[:status])
    Turbo::StreamsChannel.broadcast_replace_to(
      Pulse::STREAM, target: dom_id(incident),
      partial: "pulse/dashboard/incident", locals: { incident: incident }
    )
    Pulse.broadcast_metrics   # keep the "Open incidents" KPI honest

    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html         { redirect_to pulse_root_path }
    end
  end

  # Demo affordance: spin up a fresh open incident so the ack/resolve flow always
  # has something live to act on. Prepends it to the incidents list in every tab.
  def trigger
    service = Pulse::Service.order("RANDOM()").first
    incident = Pulse::Incident.create!(
      service:    service,
      title:      "Anomaly detected on #{service&.name || 'platform'} — error spike",
      severity:   %w[sev1 sev2 sev3].sample,
      status:     "open",
      started_at: Time.current
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      Pulse::STREAM, target: "pulse_incidents",
      partial: "pulse/dashboard/incident", locals: { incident: incident }
    )
    Pulse.broadcast_metrics

    respond_to do |format|
      format.turbo_stream { head :no_content }
      format.html         { redirect_to pulse_root_path }
    end
  end
end
