require "test_helper"

class Grid::SheetTest < ActiveSupport::TestCase
  setup do
    @sheet = Grid::Sheet.create!(name: "Budget", slug: "budget")
  end

  test "grand_total sums the row totals" do
    @sheet.rows.create!(label: "A", qty: 2, unit_price: 100, position: 0)
    @sheet.rows.create!(label: "B", qty: 3, unit_price: 50,  position: 1)
    assert_equal 350, @sheet.reload.grand_total
  end

  test "grand_total is zero with no rows" do
    assert_equal 0, @sheet.grand_total
  end

  test "rows come back ordered by position" do
    b = @sheet.rows.create!(label: "B", qty: 1, unit_price: 1, position: 1)
    a = @sheet.rows.create!(label: "A", qty: 1, unit_price: 1, position: 0)
    assert_equal [ a, b ], @sheet.rows.reload.to_a
  end

  test "requires a name and slug" do
    assert_not Grid::Sheet.new(name: "", slug: "x").valid?
    assert_not Grid::Sheet.new(name: "x", slug: "").valid?
  end

  test "to_param is the slug" do
    assert_equal "budget", @sheet.to_param
  end

  test "a row change touches the sheet for broadcast" do
    row = @sheet.rows.create!(label: "A", qty: 1, unit_price: 1, position: 0)
    original = @sheet.reload.updated_at
    travel 1.second do
      row.update!(unit_price: 99)
    end
    assert_operator @sheet.reload.updated_at, :>, original
  end
end
