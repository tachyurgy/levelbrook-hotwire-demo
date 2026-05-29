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

  test "COLORS palette is defined" do
    assert_includes Member::COLORS, "indigo"
    assert_operator Member::COLORS.size, :>, 1
  end

  test "destroying a member nullifies their assigned issues" do
    member = Member.create!(name: "Ada Okafor")
    project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    issue = project.columns.create!(name: "To Do", position: 0)
                    .issues.create!(title: "I", assignee: member)
    member.destroy
    assert_nil issue.reload.assignee_id
  end
end
