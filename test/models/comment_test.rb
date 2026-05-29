require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @issue = project.columns.create!(name: "To Do", position: 0).issues.create!(title: "I")
  end

  test "requires a body" do
    assert_not @issue.comments.build(body: "").valid?
  end

  test "member is optional" do
    assert @issue.comments.build(body: "anon comment").valid?
  end
end
