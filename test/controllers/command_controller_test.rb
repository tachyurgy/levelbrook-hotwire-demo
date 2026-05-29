require "test_helper"

class CommandControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @channel = Channel.create!(name: "general", slug: "general")
    @issue = @project.columns.create!(name: "To Do", position: 0).issues.create!(title: "Fix login")
  end

  test "blank query returns the navigation commands" do
    get command_path
    assert_response :success
    assert_match "Go to Boards", response.body
    assert_match "Go to Chat", response.body
  end

  test "query matches a project" do
    get command_path, params: { q: "Platform" }
    assert_response :success
    assert_match "LB board", response.body
  end

  test "query matches a channel" do
    get command_path, params: { q: "general" }
    assert_response :success
    assert_match "#general", response.body
  end

  test "query matches an issue by key" do
    get command_path, params: { q: @issue.key }
    assert_response :success
    assert_match @issue.title, response.body
  end
end
