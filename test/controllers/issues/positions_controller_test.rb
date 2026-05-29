require "test_helper"

class Issues::PositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @todo = @project.columns.create!(name: "To Do", position: 0)
    @done = @project.columns.create!(name: "Done", position: 1)
    @a = @todo.issues.create!(title: "A", position: 0)
    @b = @todo.issues.create!(title: "B", position: 1)
    @c = @todo.issues.create!(title: "C", position: 2)
  end

  test "moving a card to another column updates its column and position" do
    put issue_position_path(@a), params: { column_id: @done.id, position: 0 }
    assert_response :no_content
    assert_equal @done.id, @a.reload.column_id
    assert_equal 0, @a.position
  end

  test "reordering within a column reindexes positions to match the drop" do
    put issue_position_path(@c), params: { column_id: @todo.id, position: 0 }
    assert_response :no_content

    ordered = @todo.issues.order(:position)
    assert_equal %w[C A B], ordered.pluck(:title)
    assert_equal [ 0, 1, 2 ], ordered.pluck(:position)
  end

  test "a target index past the end appends the card" do
    put issue_position_path(@a), params: { column_id: @done.id, position: 99 }
    assert_response :no_content
    assert_equal @done.id, @a.reload.column_id
  end
end
