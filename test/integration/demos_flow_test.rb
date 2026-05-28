require "test_helper"

# End-to-end request flows for both demos, using the real seeders so the tests
# exercise the exact data a visitor sees.
class DemosFlowTest < ActionDispatch::IntegrationTest
  setup do
    BoardSeeder.reset!
    StorySeeder.reset!
    @board = Board.first
    @story = Story.find_by(slug: StorySeeder::SLUG)
  end

  # --- Landing page ---------------------------------------------------------
  test "landing page frames both demos" do
    get root_path
    assert_response :success
    assert_select "h1", /only.*React/i
    assert_select "a[href=?]", board_path
    assert_select "a[href=?]", story_path(@story)
  end

  # --- Kanban ---------------------------------------------------------------
  test "board page subscribes to the refresh stream and renders the iframe mirror" do
    get board_path
    assert_response :success
    assert_select "turbo-cable-stream-source"
    assert_select "[data-controller='drag-and-drop']"
    assert_select "iframe[src=?]", embed_board_path
  end

  test "embed renders the same board chromeless" do
    get embed_board_path
    assert_response :success
    assert_select "turbo-cable-stream-source"
    assert_select "header nav", false # no top nav chrome in the iframe
  end

  test "creating a card adds it to the column" do
    column = @board.columns.first
    assert_difference -> { column.cards.count }, 1 do
      post cards_path, params: { column_id: column.id, card: { title: "Fresh card" } }
    end
    assert_redirected_to board_path
  end

  test "moving a card across columns persists" do
    source = @board.columns.first
    target = @board.columns.second
    card = source.cards.first

    patch move_card_path(card), params: { column_id: target.id, position: 0 }
    assert_response :success
    assert_equal target, card.reload.column
  end

  test "reset restores the seeded board" do
    @board.cards.first.destroy
    post reset_board_path
    assert_redirected_to board_path
    assert_equal 8, Board.first.cards.count
  end

  # --- Story ----------------------------------------------------------------
  test "story show redirects into the opening scene" do
    get story_path(@story)
    assert_redirected_to story_scene_path(@story, "start")
  end

  test "a scene renders prose, choices, the live tally and the permanent bar" do
    get story_scene_path(@story, "start")
    assert_response :success
    assert_select "turbo-cable-stream-source"          # tally stream
    assert_select "#scene_#{@story.scene('start').id}_tally"
    assert_select "[data-turbo-permanent]#ambient-bar" # persistent audio bar
    assert_select "form[action*=?]", "/choices/"       # choices are real forms
  end

  test "making a choice records a pick and advances to the target scene" do
    scene = @story.scene("start")
    choice = scene.choices.first

    assert_difference -> { choice.reload.picks_count }, 1 do
      post story_choice_path(@story, choice)
    end
    assert_redirected_to story_scene_path(@story, choice.target_key)
  end

  test "an ending scene shows the ending and offers a replay" do
    get story_scene_path(@story, "ending_merge")
    assert_response :success
    assert_select "a[href=?]", story_path(@story), /again/i
  end

  test "the story is fully reachable: every choice target exists" do
    missing = @story.choices.reject { |c| @story.scenes.exists?(key: c.target_key) }
    assert_empty missing, "Dangling choice targets: #{missing.map(&:target_key)}"
  end
end
