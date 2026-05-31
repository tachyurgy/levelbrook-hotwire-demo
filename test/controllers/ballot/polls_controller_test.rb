require "test_helper"

class Ballot::PollsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ballot.seed!
    @room = Ballot::Room.first
  end

  # Swap the live Gemini call for a deterministic stub so the test is network-free.
  def stub_gemini(options)
    GeminiService.define_singleton_method(:poll_options) { |question:| options }
    yield
  ensure
    GeminiService.singleton_class.send(:remove_method, :poll_options)
  end

  test "asking a question creates an AI-generated poll with the model's options" do
    stub_gemini([ "Yes", "No", "Pilot it first" ]) do
      assert_difference -> { @room.polls.count }, 1 do
        post ballot_room_polls_path(room_slug: @room.slug),
          params: { question: "Should we adopt a four-day work week?" }, as: :turbo_stream
      end
    end

    poll = @room.polls.order(:position).last
    assert poll.ai_generated
    assert_equal "Should we adopt a four-day work week?", poll.question
    assert_equal [ "Yes", "No", "Pilot it first" ], poll.options.order(:position).map(&:label)
    assert_response :success
  end

  test "a blank question is rejected without calling the model" do
    assert_no_difference -> { @room.polls.count } do
      post ballot_room_polls_path(room_slug: @room.slug), params: { question: "  " }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "a model failure surfaces an error and creates no poll" do
    GeminiService.define_singleton_method(:poll_options) do |question:|
      raise GeminiService::Error, "boom"
    end
    assert_no_difference -> { @room.polls.count } do
      post ballot_room_polls_path(room_slug: @room.slug), params: { question: "Anything?" }, as: :turbo_stream
    end
    assert_response :bad_gateway
  ensure
    GeminiService.singleton_class.send(:remove_method, :poll_options)
  end
end
