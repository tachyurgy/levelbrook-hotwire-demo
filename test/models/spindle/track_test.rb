require "test_helper"

class Spindle::TrackTest < ActiveSupport::TestCase
  setup do
    @album = Spindle::Album.create!(title: "Night Shipping", slug: "night-shipping",
      artist: "The Collective", hue: "#7c3aed", position: 0)
    @track = @album.tracks.create!(title: "Morph & Chill", position: 0, bpm: 78,
      texture: "keys", roots: "57,53,60,55", duration_label: "3:12")
  end

  test "play_payload parses roots into an array of ints" do
    assert_equal [ 57, 53, 60, 55 ], @track.play_payload[:roots]
  end

  test "play_payload carries album title, artist, and hue" do
    payload = @track.play_payload
    assert_equal "Night Shipping", payload[:album]
    assert_equal "The Collective", payload[:artist]
    assert_equal "#7c3aed", payload[:hue]
  end

  test "play_payload includes the expected keys" do
    payload = @track.play_payload
    assert_equal %i[id title album artist hue bpm texture roots duration].sort,
      payload.keys.sort
    assert_equal "Morph & Chill", payload[:title]
    assert_equal "3:12", payload[:duration]
  end

  test "requires a title and roots" do
    assert_not @album.tracks.build(title: "", roots: "1,2", position: 1).valid?
    assert_not @album.tracks.build(title: "x", roots: "", position: 1).valid?
    assert @album.tracks.build(title: "x", roots: "1,2", position: 1).valid?
  end
end
