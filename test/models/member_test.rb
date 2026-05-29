require "test_helper"

class MemberTest < ActiveSupport::TestCase
  test "initials uses first two name parts" do
    assert_equal "AO", Member.new(name: "Ada Okafor").initials
    assert_equal "SW", Member.new(name: "Sam Whitfield Jr").initials
    assert_equal "C", Member.new(name: "Cher").initials
  end

  test "requires a name" do
    assert_not Member.new(name: "").valid?
  end
end
