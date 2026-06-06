class PagesController < ApplicationController
  def home
    @projects = Project.includes(columns: { issues: :assignee }).order(:id)
    @primary  = @projects.first
    @members  = Member.order(:id)

    issues = Issue.all
    @issue_count     = issues.count
    @points_total    = issues.sum(:points)
    @priority_counts = issues.group(:priority).count
    @high_priority   = @priority_counts.values_at("urgent", "high").compact.sum

    # Real recent activity — same source the /activities feed paginates.
    @recent = Activity.page(1, 6)
  end
end
