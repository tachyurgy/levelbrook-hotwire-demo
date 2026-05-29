class Pulse::IncidentsController < ApplicationController
  def update
    incident = Pulse::Incident.find(params[:id])
    if Pulse::Incident::STATUSES.include?(params[:status])
      incident.update!(status: params[:status])
      Turbo::StreamsChannel.broadcast_refresh_to(Pulse::STREAM)
    end
    head :no_content
  end
end
