require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Activity.reset!
    project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @col = project.columns.create!(name: "To Do", position: 0)
    30.times { |i| @col.issues.create!(title: "Issue #{i}") }
    Activity.reset!
  end

  teardown { Activity.reset! }

  test "first page renders a lazy frame for the next page" do
    get activities_path
    assert_response :success
    assert_select "turbo-frame#activity_page_2"
  end

  test "a page number below one is clamped to the first page" do
    get activities_path(page: 0)
    assert_response :success
    assert_select "turbo-frame#activity_page_2"
  end

  test "subsequent pages render the bare lazy-frame body" do
    get activities_path(page: 2)
    assert_response :success
    assert_select "turbo-frame#activity_page_2"
  end
end
