require "test_helper"

class ChannelTest < ActiveSupport::TestCase
  test "requires name and slug" do
    channel = Channel.new
    assert_not channel.valid?
    assert channel.errors[:name].any?
    assert channel.errors[:slug].any?
  end

  test "enforces a unique slug" do
    Channel.create!(name: "general", slug: "general")
    dup = Channel.new(name: "General Two", slug: "general")
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "to_param returns the slug" do
    assert_equal "general", Channel.new(slug: "general").to_param
  end

  test "messages come back in created order" do
    channel = Channel.create!(name: "general", slug: "general")
    first = channel.messages.create!(body: "first")
    second = nil
    travel 1.second do
      second = channel.messages.create!(body: "second")
    end
    assert_equal [ first, second ], channel.messages.to_a
  end
end
