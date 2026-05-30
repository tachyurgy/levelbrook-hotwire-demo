require "test_helper"

class Ballot::OptionTest < ActiveSupport::TestCase
  setup do
    @room = Ballot::Room.create!(name: "Room", slug: "room")
    @poll = @room.polls.create!(question: "Pick one", position: 0)
  end

  test "share is the rounded percentage of the given total" do
    option = @poll.options.create!(label: "A", position: 0, votes_count: 25)
    assert_equal 25, option.share(100)
    assert_equal 33, option.share(75)
  end

  test "share guards against a zero total" do
    option = @poll.options.create!(label: "A", position: 0, votes_count: 0)
    assert_equal 0, option.share(0)
  end

  test "requires a label" do
    assert_not @poll.options.build(label: "", position: 0).valid?
    assert @poll.options.build(label: "Yes", position: 0).valid?
  end
end
