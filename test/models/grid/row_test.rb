require "test_helper"

class Grid::RowTest < ActiveSupport::TestCase
  setup do
    @sheet = Grid::Sheet.create!(name: "Budget", slug: "budget")
    @row = @sheet.rows.create!(label: "Compute", category: "Infra", qty: 6, unit_price: 180, position: 0)
  end

  test "total is qty times unit_price" do
    assert_equal 1080, @row.total
  end

  test "assign_cell updates an editable string field" do
    @row.assign_cell("label", "Workers")
    assert_equal "Workers", @row.reload.label
  end

  test "assign_cell coerces numeric fields by stripping non-digits" do
    @row.assign_cell("unit_price", "$1,200")
    assert_equal 1200, @row.reload.unit_price
  end

  test "assign_cell ignores non-editable fields like total" do
    @row.assign_cell("total", "999")
    assert_equal 1080, @row.reload.total
  end

  test "assign_cell ignores unknown fields" do
    original = @row.label
    @row.assign_cell("bogus", "x")
    assert_equal original, @row.reload.label
  end

  test "requires a label" do
    assert_not @sheet.rows.build(label: "", qty: 1, unit_price: 1, position: 1).valid?
  end

  test "qty and unit_price must be non-negative numbers" do
    assert_not @sheet.rows.build(label: "x", qty: -1, unit_price: 1, position: 1).valid?
    assert_not @sheet.rows.build(label: "x", qty: 1, unit_price: -1, position: 1).valid?
    assert @sheet.rows.build(label: "x", qty: 0, unit_price: 0, position: 1).valid?
  end
end
