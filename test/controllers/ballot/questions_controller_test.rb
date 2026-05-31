require "test_helper"

class Ballot::QuestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ballot.seed!
    @room = Ballot::Room.first
  end

  # Regression: the form posts `question[body]` (scoped) and the controller reads
  # params.dig(:question, :body). Before the form was scoped the field was bare
  # `body`, so the body always arrived blank and the create silently 422'd —
  # "clicking Ask did nothing".
  test "asking a question creates it from the scoped body param" do
    assert_difference -> { @room.questions.count }, 1 do
      post ballot_room_questions_path(room_slug: @room.slug),
        params: { question: { body: "Can we automate releases?" } }, as: :turbo_stream
    end
    assert_equal "Can we automate releases?", @room.questions.order(:created_at).last.body
    assert_response :success
  end

  test "a blank body is rejected" do
    assert_no_difference -> { @room.questions.count } do
      post ballot_room_questions_path(room_slug: @room.slug),
        params: { question: { body: "   " } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end
end
