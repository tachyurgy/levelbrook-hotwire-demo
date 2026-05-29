require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @todo = @project.columns.create!(name: "To Do", position: 0)
  end

  test "requires name, key and slug" do
    project = Project.new
    assert_not project.valid?
    assert project.errors[:name].any?
    assert project.errors[:key].any?
    assert project.errors[:slug].any?
  end

  test "enforces unique slug and key" do
    dup_slug = Project.new(name: "Other", key: "XX", slug: "platform")
    assert_not dup_slug.valid?
    assert dup_slug.errors[:slug].any?

    dup_key = Project.new(name: "Other", key: "LB", slug: "other")
    assert_not dup_key.valid?
    assert dup_key.errors[:key].any?
  end

  test "to_param returns the slug" do
    assert_equal "platform", @project.to_param
  end

  test "next_issue_number increments atomically and persists" do
    assert_equal 1, @project.next_issue_number
    assert_equal 2, @project.next_issue_number
    assert_equal 2, @project.reload.issues_seq
  end

  test "issues are reachable through columns" do
    a = @todo.issues.create!(title: "A")
    done = @project.columns.create!(name: "Done", position: 1)
    b = done.issues.create!(title: "B")
    assert_includes @project.issues, a
    assert_includes @project.issues, b
  end
end
