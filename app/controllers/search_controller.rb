# Debounced live search. The form auto-submits into the results frame as you
# type; the URL advances so results are shareable/back-button-able.
class SearchController < ApplicationController
  def show
    @query = params[:q].to_s.strip
    @results =
      if @query.present?
        Issue.includes(:assignee, column: :project)
             .where("title LIKE :q OR description LIKE :q", q: "%#{@query}%")
             .order("issues.updated_at DESC")
             .limit(40)
      else
        Issue.none
      end
  end
end
