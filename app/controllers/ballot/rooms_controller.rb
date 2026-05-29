class Ballot::RoomsController < ApplicationController
  before_action :set_room, only: %i[show reset]

  def index
    rooms = Ballot::Room.order(:id)
    redirect_to ballot_room_path(rooms.first) if rooms.any?
  end

  def show
    @polls = @room.polls.includes(:options)
    @questions = @room.questions
  end

  def reset
    slug = @room.slug
    Ballot::Room.destroy_all
    Ballot.seed!
    redirect_to ballot_room_path(Ballot::Room.find_by(slug: slug) || Ballot::Room.first),
      notice: "Room reset to the demo state."
  end

  private

  def set_room
    @room = Ballot::Room.find_by!(slug: params[:slug])
  end
end
