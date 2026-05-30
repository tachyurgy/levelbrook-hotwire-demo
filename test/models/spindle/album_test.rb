require "test_helper"

class Spindle::AlbumTest < ActiveSupport::TestCase
  setup do
    @album = Spindle::Album.create!(title: "Night Shipping", slug: "night-shipping",
      artist: "The Collective", hue: "#7c3aed", position: 0)
  end

  test "tracks come back ordered by position" do
    b = @album.tracks.create!(title: "B", position: 1, roots: "1,2")
    a = @album.tracks.create!(title: "A", position: 0, roots: "1,2")
    assert_equal [ a, b ], @album.tracks.reload.to_a
  end

  test "requires a title, slug, and artist" do
    assert_not Spindle::Album.new(title: "", slug: "x", artist: "y").valid?
    assert_not Spindle::Album.new(title: "x", slug: "", artist: "y").valid?
    assert_not Spindle::Album.new(title: "x", slug: "y", artist: "").valid?
    assert Spindle::Album.new(title: "x", slug: "y", artist: "z").valid?
  end

  test "to_param is the slug" do
    assert_equal "night-shipping", @album.to_param
  end
end
