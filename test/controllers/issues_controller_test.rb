require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @todo = @project.columns.create!(name: "To Do", position: 0)
    @done = @project.columns.create!(name: "Done", position: 1)
    @member = Member.create!(name: "Ada Okafor")
    @issue = @todo.issues.create!(title: "Original", description: "d")
  end

  test "show loads the issue into the modal frame" do
    get issue_path(@issue)
    assert_response :success
    assert_select "turbo-frame#modal"
    assert_match @issue.title, response.body
  end

  test "edit_field renders an edit form for an allowed field" do
    get issue_field_path(@issue, "title")
    assert_response :success
    assert_select "form"
  end

  test "edit_field with cancel renders the read-only field" do
    get issue_field_path(@issue, "title", cancel: true)
    assert_response :success
    assert_match @issue.title, response.body
  end

  test "edit_field rejects an unknown field" do
    get issue_field_path(@issue, "evil")
    assert_response :not_found
  end

  test "update_field saves a plain field" do
    patch issue_field_path(@issue, "title"), params: { issue: { title: "Renamed" } }
    assert_response :success
    assert_equal "Renamed", @issue.reload.title
  end

  test "update_field for status moves the issue to the target column" do
    patch issue_field_path(@issue, "status"), params: { issue: { column_id: @done.id } }
    assert_response :success
    assert_equal @done.id, @issue.reload.column_id
  end

  test "update_field for assignee sets and then clears the assignee" do
    patch issue_field_path(@issue, "assignee"), params: { issue: { assignee_id: @member.id } }
    assert_equal @member.id, @issue.reload.assignee_id

    patch issue_field_path(@issue, "assignee"), params: { issue: { assignee_id: "" } }
    assert_nil @issue.reload.assignee_id
  end
end
