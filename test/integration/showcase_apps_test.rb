require "test_helper"

# Covers the multi-app portfolio: the gallery switcher plus each app's core
# realtime/optimistic endpoints.
class ShowcaseAppsTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(name: "Ada Okafor")
    Ballot.seed!
    Pulse.seed!
    Spindle.seed!
    Grid.seed!
  end

  # --- Gallery ---------------------------------------------------------
  test "gallery lists every app with its entry link" do
    get root_path
    assert_response :success
    assert_select "a", text: /Pulse|Ballot|Grid|Spindle/, minimum: 4
  end

  # --- Ballot ----------------------------------------------------------
  test "ballot root redirects to the first room" do
    get ballot_root_path
    assert_redirected_to ballot_room_path(Ballot::Room.first)
  end

  test "ballot room renders polls and Q&A" do
    room = Ballot::Room.first
    get ballot_room_path(room)
    assert_response :success
    assert_match room.polls.first.question, response.body
    assert_select "turbo-cable-stream-source"
  end

  test "voting bumps an option" do
    room = Ballot::Room.first
    poll = room.polls.first
    option = poll.options.first
    assert_difference -> { option.reload.votes_count }, 1 do
      post ballot_room_poll_votes_path(room, poll), params: { option_id: option.id }
    end
    assert_response :no_content
  end

  test "asking a question creates it" do
    room = Ballot::Room.first
    assert_difference -> { room.questions.count }, 1 do
      post ballot_room_questions_path(room), params: { question: { body: "What's next?" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "upvoting a question bumps it" do
    room = Ballot::Room.first
    question = room.questions.first
    assert_difference -> { question.reload.upvotes_count }, 1 do
      post ballot_room_question_upvote_path(room, question)
    end
    assert_response :no_content
  end

  # --- Pulse -----------------------------------------------------------
  test "pulse dashboard renders services and incidents" do
    get pulse_root_path
    assert_response :success
    assert_match "Service health", response.body
    assert_match Pulse::Service.first.name, response.body
  end

  test "running a deploy enqueues the deploy job" do
    service = Pulse::Service.where.not(status: "down").first
    assert_enqueued_with(job: Pulse::DeployJob) do
      post pulse_deploys_path, params: { service_id: service.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "visiting the dashboard starts the always-on ticker" do
    Rails.cache.delete(Pulse::BEAT_KEY)
    assert_enqueued_with(job: Pulse::TickJob) do
      get pulse_root_path
    end
    assert_response :success
  end

  test "triggering an incident creates an open one" do
    assert_difference -> { Pulse::Incident.where(status: "open").count }, 1 do
      post pulse_trigger_incident_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :no_content
  end

  test "acknowledging an incident changes its status" do
    incident = Pulse::Incident.where(status: "open").first
    patch pulse_incident_path(incident, status: "ack"),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :no_content
    assert_equal "ack", incident.reload.status
  end

  # --- Grid ------------------------------------------------------------
  test "grid sheet renders with a grand total" do
    sheet = Grid::Sheet.first
    get grid_sheet_path(sheet)
    assert_response :success
    assert_match "Grand total", response.body
  end

  test "editing a cell recomputes the row total" do
    row = Grid::Sheet.first.rows.first
    patch grid_cell_path(row), params: { field: "qty", row: { qty: "10" } }
    assert_response :redirect
    assert_equal 10, row.reload.qty
  end

  # --- Spindle ---------------------------------------------------------
  test "spindle index and album render" do
    get spindle_root_path
    assert_response :success
    album = Spindle::Album.first
    get spindle_album_path(album)
    assert_response :success
    # Title escaped in HTML; assert one free of special chars.
    assert_match "Permanent State", response.body
    assert_select "[data-spindle-play-track-value]", minimum: 1
  end

  # --- Cadence reactions ----------------------------------------------
  test "reacting to a message increments the emoji" do
    channel = Channel.create!(name: "general", slug: "general", topic: "Hi")
    message = channel.messages.create!(member: @member, body: "ship it")
    post channel_message_reaction_path(channel, message), params: { emoji: "🚀" }
    assert_response :no_content
    assert_equal 1, message.reload.reactions_hash["🚀"]
  end
end
