class IssuesController < ApplicationController
  before_action :set_issue

  # Lazy-loaded into the modal frame when a card is clicked.
  def show
    @members = Member.order(:id)
  end

  # --- Inline frame-swap editing of a single field ----------------------
  FIELDS = %w[title description status assignee].freeze

  def edit_field
    @field = permitted_field
    @members = Member.order(:id)
    template = params[:cancel] ? @field : "#{@field}_edit"
    render partial: "issues/fields/#{template}", locals: { issue: @issue, members: @members }
  end

  def update_field
    @field = permitted_field

    case @field
    when "status"
      target = Column.find(params.dig(:issue, :column_id))
      @issue.update(column: target, position: target.issues.count)
    when "assignee"
      @issue.update(assignee_id: params.dig(:issue, :assignee_id).presence)
    else
      @issue.update(@field => params.dig(:issue, @field))
    end

    @members = Member.order(:id)
    render partial: "issues/fields/#{@field}", locals: { issue: @issue }
  end

  private

  def set_issue
    @issue = Issue.includes(:assignee, :comments, column: :project).find(params[:id] || params[:issue_id])
  end

  def permitted_field
    FIELDS.include?(params[:field]) ? params[:field] : (raise ActionController::RoutingError, "unknown field")
  end

end
