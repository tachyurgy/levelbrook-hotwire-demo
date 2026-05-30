require "test_helper"

class Ballot::PollTest < ActiveSupport::TestCase
  setup do
    @room = Ballot::Room.create!(name: "Room", slug: "room")
    @poll = @room.polls.create!(question: "Pick one", position: 0)
  end

  test "total_votes sums the option vote counts" do
    @poll.options.create!(label: "A", position: 0, votes_count: 7)
    @poll.options.create!(label: "B", position: 1, votes_count: 12)
    assert_equal 19, @poll.reload.total_votes
  end

  test "total_votes is zero with no options" do
    assert_equal 0, @poll.total_votes
  end

  test "options come back ordered by position" do
    c = @poll.options.create!(label: "C", position: 2, votes_count: 1)
    a = @poll.options.create!(label: "A", position: 0, votes_count: 1)
    b = @poll.options.create!(label: "B", position: 1, votes_count: 1)
    assert_equal [ a, b, c ], @poll.options.reload.to_a
  end

  test "requires a question" do
    assert_not @room.polls.build(question: "", position: 1).valid?
  end
end
