require "test_helper"

class Ballot::RoomTest < ActiveSupport::TestCase
  setup do
    @room = Ballot::Room.create!(name: "Room", slug: "room")
  end

  test "requires a name and slug" do
    assert_not Ballot::Room.new(name: "", slug: "x").valid?
    assert_not Ballot::Room.new(name: "x", slug: "").valid?
    assert Ballot::Room.new(name: "x", slug: "x").valid?
  end

  test "to_param is the slug" do
    assert_equal "room", @room.to_param
  end

  test "questions are ordered by upvotes desc then created_at asc" do
    low_old  = @room.questions.create!(author: "A", body: "old low",  upvotes_count: 1)
    high     = @room.questions.create!(author: "B", body: "high",     upvotes_count: 9)
    low_new  = nil
    travel 1.second do
      low_new = @room.questions.create!(author: "C", body: "new low", upvotes_count: 1)
    end
    assert_equal [ high, low_old, low_new ], @room.questions.reload.to_a
  end

  test "creating a question touches the room" do
    original = @room.reload.updated_at
    travel 1.second do
      @room.questions.create!(author: "A", body: "ping")
    end
    assert_operator @room.reload.updated_at, :>, original
  end

  test "updating an option touches the room through its poll" do
    poll = @room.polls.create!(question: "Q", position: 0)
    option = poll.options.create!(label: "A", position: 0, votes_count: 0)
    original = @room.reload.updated_at
    travel 1.second do
      option.update!(votes_count: 1)
    end
    assert_operator @room.reload.updated_at, :>, original
  end

  test "updating a question touches the room" do
    question = @room.questions.create!(author: "A", body: "ping", upvotes_count: 0)
    original = @room.reload.updated_at
    travel 1.second do
      question.update!(upvotes_count: 1)
    end
    assert_operator @room.reload.updated_at, :>, original
  end
end
