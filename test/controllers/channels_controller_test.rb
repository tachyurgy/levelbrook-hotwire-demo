require "test_helper"

class ChannelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @channel = Channel.create!(name: "general", slug: "general", topic: "Welcome")
    @member = Member.create!(name: "Ada Okafor")
  end

  test "index redirects to the first channel" do
    get channels_path
    assert_redirected_to channel_path(@channel)
  end

  test "show renders the channel with its messages" do
    @channel.messages.create!(body: "hello world", member: @member)
    get channel_path(@channel)
    assert_response :success
    assert_match "hello world", response.body
  end
end
