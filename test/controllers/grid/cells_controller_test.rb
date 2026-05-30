require "test_helper"

class Grid::CellsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Grid.seed!
    @row = Grid::Sheet.first.rows.first
  end

  test "updating an editable cell changes it and returns no_content" do
    put grid_cell_path(@row), params: { field: "label", row: { label: "Renamed" } }
    assert_response :no_content
    assert_equal "Renamed", @row.reload.label
  end

  test "a numeric cell is coerced from a formatted string" do
    put grid_cell_path(@row), params: { field: "unit_price", row: { unit_price: "$1,200" } }
    assert_response :no_content
    assert_equal 1200, @row.reload.unit_price
  end

  test "a non-editable field is ignored" do
    before = @row.unit_price
    put grid_cell_path(@row), params: { field: "total", row: { total: "999" } }
    assert_response :no_content
    assert_equal before, @row.reload.unit_price
  end
end
