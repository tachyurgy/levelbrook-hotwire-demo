# Infinite scroll via deferred lazy frames. Each page renders a list plus a
# lazy turbo_frame_tag pointing at the next page; the frame loads when it
# scrolls into view and renders the next lazy frame in turn.
class ActivitiesController < ApplicationController
  PER_PAGE = 12

  def index
    @page = [ params[:page].to_i, 1 ].max
    @activities = Activity.page(@page, PER_PAGE)
    @next_page = @page + 1 if Activity.total > @page * PER_PAGE

    # Page 1 is the full view; subsequent pages are the lazy-frame body that
    # Turbo splices in when the frame scrolls into view.
    render :page, layout: false if @page > 1
  end
end
