class Ballot::QuestionsController < ApplicationController
  def create
    @room = Ballot::Room.find_by!(slug: params[:room_slug])
    @question = @room.questions.create!(
      body: params.dig(:question, :body).to_s.strip,
      author: current_member&.name || "Guest"
    )
    # Creating the question touches the room -> broadcasts_refreshes morphs the
    # list (re-sorted by upvotes) for everyone. The asker just gets a fresh form.
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "new_question", partial: "ballot/rooms/new_question", locals: { room: @room }
        )
      end
      format.html { redirect_to ballot_room_path(@room) }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
