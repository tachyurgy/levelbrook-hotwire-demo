require "test_helper"

class Spindle::AlbumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Spindle.seed!
    @album = Spindle::Album.order(:position).first
  end

  test "index renders successfully" do
    get spindle_albums_path
    assert_response :success
  end

  test "show renders a seeded album" do
    get spindle_album_path(@album)
    assert_response :success
  end
end
