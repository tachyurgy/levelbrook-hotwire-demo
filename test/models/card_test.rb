require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @board = Board.create!(name: "Test Board", slug: "test-#{SecureRandom.hex(4)}")
    @todo  = @board.columns.create!(name: "Todo", position: 0)
    @doing = @board.columns.create!(name: "Doing", position: 1)
    @a = @todo.cards.create!(title: "A", position: 0)
    @b = @todo.cards.create!(title: "B", position: 1)
    @c = @todo.cards.create!(title: "C", position: 2)
  end

  test "move_to! reorders within the same column and keeps positions dense" do
    @c.move_to!(@todo, 0)

    assert_equal %w[C A B], @todo.cards.ordered.pluck(:title)
    assert_equal [ 0, 1, 2 ], @todo.cards.ordered.pluck(:position)
  end

  test "move_to! moves a card across columns and renumbers both" do
    @a.move_to!(@doing, 0)

    assert_equal @doing, @a.reload.column
    assert_equal %w[B C], @todo.cards.ordered.pluck(:title)
    assert_equal [ 0, 1 ], @todo.cards.ordered.pluck(:position)
    assert_equal [ 0 ], @doing.cards.ordered.pluck(:position)
  end

  test "move_to! clamps an out-of-range position to the end" do
    @a.move_to!(@doing, 99)
    assert_equal 0, @a.reload.position
    assert_equal [ @a.id ], @doing.cards.ordered.pluck(:id)
  end

  test "moving a card touches the board so broadcasts_refreshes fires" do
    original = @board.updated_at
    travel 1.second do
      @a.move_to!(@doing, 0)
    end
    assert_operator @board.reload.updated_at, :>, original
  end
end
