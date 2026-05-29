require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @col = @project.columns.create!(name: "To Do", position: 0)
    @issue = @col.issues.create!(title: "Payment bug", description: "stripe webhook retries")
  end

  test "matches on title" do
    get search_path, params: { q: "Payment" }
    assert_response :success
    assert_match @issue.key, response.body
  end

  test "matches on description" do
    get search_path, params: { q: "stripe" }
    assert_response :success
    assert_match @issue.key, response.body
  end

  test "no matches renders the empty state" do
    get search_path, params: { q: "nonexistent-term" }
    assert_response :success
    assert_match(/No issues match/, response.body)
  end

  test "blank query renders without error" do
    get search_path, params: { q: "" }
    assert_response :success
  end
end
