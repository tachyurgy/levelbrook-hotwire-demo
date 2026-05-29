require "test_helper"

class IssueTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Test", key: "TST", slug: "test")
    @todo = @project.columns.create!(name: "To Do", position: 0)
    @done = @project.columns.create!(name: "Done", position: 1)
    @member = Member.create!(name: "Ada Okafor")
  end

  test "auto-assigns a per-project sequential number on create" do
    a = @todo.issues.create!(title: "First")
    b = @todo.issues.create!(title: "Second")
    assert_equal 1, a.number
    assert_equal 2, b.number
    assert_equal "TST-1", a.key
    assert_equal "TST-2", b.key
  end

  test "key combines project key and number" do
    issue = @todo.issues.create!(title: "Has key")
    assert_equal "TST-#{issue.number}", issue.key
  end

  test "validates label and priority inclusion" do
    issue = @todo.issues.build(title: "Bad", label: "nope", priority: "whenever")
    assert_not issue.valid?
    assert issue.errors[:label].any?
    assert issue.errors[:priority].any?
  end

  test "label_color maps labels to palette colors" do
    assert_equal "rose", @todo.issues.create!(title: "Bug", label: "bug").label_color
    assert_equal "emerald", @todo.issues.create!(title: "Feat", label: "feature").label_color
  end

  test "moving columns touches the project for broadcast" do
    issue = @todo.issues.create!(title: "Move me")
    original = @project.reload.updated_at
    travel 1.second do
      issue.update!(column: @done)
    end
    assert_operator @project.reload.updated_at, :>, original
  end

  test "validates points are within 0..21" do
    assert_not @todo.issues.build(title: "x", points: -1).valid?
    assert_not @todo.issues.build(title: "x", points: 22).valid?
    assert @todo.issues.build(title: "x", points: 0).valid?
    assert @todo.issues.build(title: "x", points: 21).valid?
  end

  test "assignee is optional" do
    assert @todo.issues.build(title: "no assignee").valid?
  end

  test "does not overwrite an explicitly provided number" do
    issue = @todo.issues.create!(title: "manual", number: 99)
    assert_equal 99, issue.number
  end

  test "comments come back oldest first" do
    issue = @todo.issues.create!(title: "with comments")
    first = issue.comments.create!(body: "one")
    second = nil
    travel 1.second do
      second = issue.comments.create!(body: "two")
    end
    assert_equal [ first, second ], issue.comments.to_a
  end

  test "delegates project to its column" do
    issue = @todo.issues.create!(title: "deleg")
    assert_equal @project, issue.project
  end
end
