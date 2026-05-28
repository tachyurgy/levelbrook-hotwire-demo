class ChoicesController < ApplicationController
  # A reader picks a branch. We record the pick (which broadcasts the updated
  # tally to everyone on this scene) then redirect to the target scene. The
  # redirect is a normal Turbo Drive visit, animated by a View Transition and
  # rendered with the morph refresh method, so the ambient-audio bar marked
  # data-turbo-permanent never reloads. Works as a plain form post with JS off.
  def choose
    @story  = Story.find_by!(slug: params[:story_slug])
    @choice = Choice.find(params[:id])
    @choice.record_pick!

    redirect_to story_scene_path(@story, @choice.target_key)
  end
end
