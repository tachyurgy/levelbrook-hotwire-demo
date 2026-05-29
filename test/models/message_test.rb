require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @channel = Channel.create!(name: "general", slug: "general")
  end

  test "requires a body" do
    assert_not @channel.messages.build(body: "").valid?
  end

  test "member is optional" do
    assert @channel.messages.build(body: "hi there").valid?
  end
end
