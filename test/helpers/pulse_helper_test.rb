require "test_helper"

class PulseHelperTest < ActionView::TestCase
  test "returns empty path strings for fewer than two points" do
    assert_equal "", sparkline([]).fetch(:line)
    assert_equal "", sparkline([]).fetch(:area)
    assert_equal "", sparkline([ 5 ]).fetch(:line)
  end

  test "produces a line with one coordinate pair per point" do
    result = sparkline([ 10, 20, 30, 40 ])
    assert_equal 4, result[:line].split(" ").size
    result[:line].split(" ").each do |pair|
      assert_match(/\A-?\d+(\.\d+)?,-?\d+(\.\d+)?\z/, pair)
    end
  end

  test "area wraps the line with two baseline anchor points" do
    points = [ 10, 20, 30 ]
    result = sparkline(points)
    # area = leading baseline anchor + line coords + trailing baseline anchor
    assert_equal points.size + 2, result[:area].split(" ").size
  end

  test "handles a flat series without dividing by zero" do
    result = sparkline([ 50, 50, 50, 50 ])
    assert_equal 4, result[:line].split(" ").size
    refute_includes result[:line], "NaN"
    refute_includes result[:line], "Infinity"
  end

  test "returns the supplied width and height" do
    result = sparkline([ 1, 2 ], width: 300, height: 60)
    assert_equal 300, result[:w]
    assert_equal 60, result[:h]
  end
end
