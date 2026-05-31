# Turn an audience question into a live poll: we ask Gemini for the answer
# options, persist the poll + options, then touch the room so the same
# broadcasts_refreshes morph that powers voting streams the brand-new poll onto
# every open browser. The asker just gets a fresh, cleared form back.
class Ballot::PollsController < ApplicationController
  def create
    @room = Ballot::Room.find_by!(slug: params[:room_slug])
    question = params[:question].to_s.strip

    if question.blank?
      return render_form(error: "Type a question first.", status: :unprocessable_entity)
    end

    labels = GeminiService.poll_options(question: question)

    Ballot::Poll.transaction do
      poll = @room.polls.create!(
        question: question,
        ai_generated: true,
        asker: current_member&.name || "Guest",
        position: (@room.polls.maximum(:position) || -1) + 1
      )
      labels.each_with_index do |label, i|
        poll.options.create!(label: label, position: i, votes_count: 0)
      end
    end
    @room.touch # fires the page-refresh broadcast -> morphs the new poll in

    render_form
  rescue GeminiService::Error => e
    Rails.logger.error("[Ballot] AI poll generation failed: #{e.message}")
    render_form(error: "Couldn't reach the model just now — try again.", status: :bad_gateway)
  end

  private

  def render_form(error: nil, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "new_poll", partial: "ballot/rooms/new_poll", locals: { room: @room, error: error }
        ), status: status
      end
      format.html { redirect_to ballot_room_path(@room) }
    end
  end
end
