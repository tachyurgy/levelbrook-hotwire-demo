# A vote bumps one option and touches the room. The room's broadcasts_refreshes
# then morphs every connected client's tallies. The voter's own client already
# bumped the bar optimistically (poll_controller.js); the morph reconciles the
# exact numbers. Response is 204 — all UI updates arrive via the broadcast.
class Ballot::VotesController < ApplicationController
  def create
    room = Ballot::Room.find_by!(slug: params[:room_slug])
    option = room.polls.find(params[:poll_id]).options.find(params[:option_id])
    option.increment!(:votes_count)
    room.touch
    head :no_content
  end
end
