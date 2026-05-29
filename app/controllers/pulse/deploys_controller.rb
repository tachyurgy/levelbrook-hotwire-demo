class Pulse::DeploysController < ApplicationController
  def create
    service = Pulse::Service.find(params[:service_id])
    Pulse::DeployJob.perform_later(service.id)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "deploy_status", partial: "pulse/dashboard/deploy_status",
          locals: { service: service, pct: 0, done: false, active: true }
        )
      end
      format.html { redirect_to pulse_root_path }
    end
  end
end
