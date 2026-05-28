class StoriesController < ApplicationController
  def index
    @stories = Story.all
  end

  def show
    @story = Story.find_by!(slug: params[:slug])
    redirect_to story_scene_path(@story, @story.opening_scene.key)
  end
end
