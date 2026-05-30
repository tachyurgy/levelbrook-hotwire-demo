require "test_helper"

class Ballot::RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ballot.seed!
    @room = Ballot::Room.order(:id).first
  end

  test "index redirects to the first room" do
    get ballot_rooms_path
    assert_redirected_to ballot_room_path(@room)
  end

  test "show renders successfully" do
    get ballot_room_path(@room)
    assert_response :success
  end

  test "reset reseeds the rooms" do
    @room.questions.create!(author: "X", body: "extra question")
    post reset_ballot_room_path(@room)
    assert_response :redirect
    # destroy_all + re-seed leaves exactly the seeded room set
    assert_equal 2, Ballot::Room.count
  end
end
