require "test_helper"

class Ballot::VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ballot.seed!
    @room = Ballot::Room.first
    @poll = @room.polls.first
    @option = @poll.options.first
  end

  test "voting increments the option's votes_count and returns no_content" do
    assert_difference -> { @option.reload.votes_count }, 1 do
      post ballot_room_poll_votes_path(room_slug: @room.slug, poll_id: @poll.id, option_id: @option.id)
    end
    assert_response :no_content
  end
end
