require "test_helper"

class ColumnTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @col = @project.columns.create!(name: "To Do", position: 0)
  end

  test "requires a name" do
    assert_not @project.columns.build(name: "").valid?
  end

  test "over_wip_limit? is false when no limit is set" do
    @col.update!(wip_limit: nil)
    3.times { |i| @col.issues.create!(title: "I#{i}") }
    assert_not @col.reload.over_wip_limit?
  end

  test "over_wip_limit? trips only when the issue count exceeds the limit" do
    @col.update!(wip_limit: 2)
    2.times { |i| @col.issues.create!(title: "I#{i}") }
    assert_not @col.reload.over_wip_limit?, "at the limit is not over"

    @col.issues.create!(title: "third")
    assert @col.reload.over_wip_limit?, "exceeding the limit is over"
  end

  test "creating an issue touches the parent project for broadcast" do
    before = @project.reload.updated_at
    travel 1.second do
      @col.issues.create!(title: "touch me")
    end
    assert_operator @project.reload.updated_at, :>, before
  end
end
