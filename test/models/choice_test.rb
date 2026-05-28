require "test_helper"

class ChoiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @story = Story.create!(title: "S", slug: "s-#{SecureRandom.hex(4)}")
    @scene = @story.scenes.create!(key: "start", heading: "H", body: "B", mood: "calm")
    @story.scenes.create!(key: "left", heading: "L", body: "B")
    @story.scenes.create!(key: "right", heading: "R", body: "B")
    @left  = @scene.choices.create!(label: "Go left", target_key: "left", position: 0)
    @right = @scene.choices.create!(label: "Go right", target_key: "right", position: 1)
  end

  test "share is zero before any picks" do
    assert_equal 0, @left.share
  end

  test "record_pick! increments the count" do
    assert_difference -> { @left.reload.picks_count }, 1 do
      @left.record_pick!
    end
  end

  test "share reflects the proportion of picks across the scene" do
    3.times { @left.record_pick! }
    1.times { @right.record_pick! }

    assert_equal 75, @left.reload.share
    assert_equal 25, @right.reload.share
  end

  test "record_pick! enqueues a tally broadcast" do
    assert_enqueued_jobs 1, only: Turbo::Streams::ActionBroadcastJob do
      @left.record_pick!
    end
  end

  test "target_scene resolves the branch destination" do
    assert_equal "left", @left.target_scene.key
  end
end
