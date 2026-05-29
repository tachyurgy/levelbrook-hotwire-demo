require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(name: "Ada Okafor")
    project = Project.create!(name: "Platform", key: "LB", slug: "platform")
    @issue = project.columns.create!(name: "To Do", position: 0).issues.create!(title: "I")
  end

  test "a valid comment is created and resets the composer" do
    assert_difference -> { @issue.comments.count }, 1 do
      post issue_comments_path(@issue), params: { comment: { body: "Looks good" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
  end

  test "a blank comment is rejected" do
    assert_no_difference -> { @issue.comments.count } do
      post issue_comments_path(@issue), params: { comment: { body: "" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end
end
