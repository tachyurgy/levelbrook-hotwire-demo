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
end
