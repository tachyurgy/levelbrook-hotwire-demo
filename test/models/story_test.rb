require "test_helper"

class StoryTest < ActiveSupport::TestCase
  setup do
    @story = Story.create!(title: "S", slug: "s-#{SecureRandom.hex(4)}")
    @start = @story.scenes.create!(key: "start", heading: "H", body: "B")
    @end   = @story.scenes.create!(key: "end", heading: "E", body: "B", ending: true, ending_kind: "Fin")
  end

  test "opening_scene prefers the scene keyed 'start'" do
    assert_equal @start, @story.opening_scene
  end

  test "scene looks up by key and raises for an unknown key" do
    assert_equal @end, @story.scene("end")
    assert_raises(ActiveRecord::RecordNotFound) { @story.scene("missing") }
  end

  test "to_param uses the slug" do
    assert_equal @story.slug, @story.to_param
  end

  test "ending scenes are flagged" do
    assert @end.ending?
    assert_not @start.ending?
  end
end
