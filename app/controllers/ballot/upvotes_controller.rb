# Upvoting a question bumps its counter and touches the room, so the morph
# re-sorts the Q&A list for every client. Optimistic bump is client-side.
class Ballot::UpvotesController < ApplicationController
  def create
    room = Ballot::Room.find_by!(slug: params[:room_slug])
    question = room.questions.find(params[:question_id])
    question.increment!(:upvotes_count)
    room.touch
    head :no_content
  end
end
