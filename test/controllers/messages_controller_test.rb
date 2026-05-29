require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(name: "Ada Okafor")
    @channel = Channel.create!(name: "general", slug: "general")
  end

  test "a valid message is created" do
    assert_difference -> { @channel.messages.count }, 1 do
      post channel_messages_path(@channel), params: { message: { body: "hi" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "a blank message is rejected" do
    assert_no_difference -> { @channel.messages.count } do
      post channel_messages_path(@channel), params: { message: { body: "" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end
end
