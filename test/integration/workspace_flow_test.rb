require "test_helper"

class WorkspaceFlowTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(name: "Ada Okafor")
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @todo = @project.columns.create!(name: "To Do", position: 0)
    @done = @project.columns.create!(name: "Done", position: 1)
    @issue = @todo.issues.create!(title: "Drag me", description: "desc", assignee: @member)
    @channel = Channel.create!(name: "general", slug: "general", topic: "Hi")
  end

  test "landing page renders the showcase" do
    get root_path
    assert_response :success
    assert_select "h1", /HTML over the wire/
  end

  test "board shows columns and issues" do
    get project_path(@project)
    assert_response :success
    assert_select "h1", "Platform"
    assert_match @issue.key, response.body
  end

  test "issue detail loads into the modal frame" do
    get issue_path(@issue)
    assert_response :success
    assert_select "turbo-frame#modal"
    assert_match @issue.title, response.body
  end

  test "dragging a card persists new column and position" do
    put issue_position_path(@issue), params: { column_id: @done.id, position: 0 }.to_json,
        headers: { "Content-Type" => "application/json" }
    assert_response :no_content
    assert_equal @done.id, @issue.reload.column_id
  end

  test "inline field edit swaps in an edit form then saves" do
    get issue_field_path(@issue, :title)
    assert_response :success
    assert_select "form"

    patch issue_field_path(@issue, :title), params: { issue: { title: "New title" } }
    assert_response :success
    assert_equal "New title", @issue.reload.title
  end

  test "posting a comment appends it" do
    assert_difference -> { @issue.comments.count }, 1 do
      post issue_comments_path(@issue), params: { comment: { body: "Nice" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "posting a chat message creates it" do
    assert_difference -> { @channel.messages.count }, 1 do
      post channel_messages_path(@channel), params: { message: { body: "Hello" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "live search filters issues into a frame" do
    get search_path, params: { q: "Drag" }
    assert_response :success
    assert_match @issue.key, response.body

    get search_path, params: { q: "zzz-no-match" }
    assert_response :success
    assert_match(/No issues match/, response.body)
  end

  test "command palette returns server-rendered results" do
    get command_path, params: { q: "general" }
    assert_response :success
    assert_match "#general", response.body
  end

  test "signup validate streams field-level errors" do
    post validate_signups_path, params: { field: "email", signup: { email: "bad" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match(/valid email/, response.body)
  end

  test "signup create succeeds with valid data" do
    post signups_path, params: { signup: { workspace_name: "Acme", subdomain: "acme", email: "a@b.com", seats: 4 } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/is ready/, response.body)
  end

  test "activity feed paginates via lazy frames" do
    20.times { |i| @todo.issues.create!(title: "Issue #{i}") }
    Activity.reset!
    get activities_path
    assert_response :success
    assert_select "turbo-frame[id^=activity_page_]"

    get activities_path(page: 2)
    assert_response :success
    assert_select "turbo-frame#activity_page_2"
  end

  test "board reset rebuilds the demo board" do
    post reset_project_path(@project)
    assert_response :redirect
    assert @project.reload.columns.any?
  end
end
