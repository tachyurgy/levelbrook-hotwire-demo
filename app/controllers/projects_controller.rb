class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show reset]

  def index
    @projects = Project.all
  end

  def show
    @columns = @project.columns.includes(issues: :assignee)
    @members = Member.order(:id)
  end

  def reset
    Seeds.reset_project!(@project)
    redirect_to project_path(@project), notice: "Board reset to the demo state."
  end

  private

  def set_project
    @project = Project.find_by!(slug: params[:slug])
  end
end
