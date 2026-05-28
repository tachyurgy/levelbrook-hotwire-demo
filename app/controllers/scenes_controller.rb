class ScenesController < ApplicationController
  def show
    @story = Story.find_by!(slug: params[:story_slug])
    @scene = @story.scene(params[:key])
  end
end
