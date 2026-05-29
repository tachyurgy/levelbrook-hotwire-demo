require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  test "new renders the form" do
    get new_signup_path
    assert_response :success
    assert_select "form"
  end

  test "validate streams an email error" do
    post validate_signups_path, params: { field: "email", signup: { email: "nope" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/valid email/, response.body)
  end

  test "validate flags a reserved subdomain" do
    post validate_signups_path, params: { field: "subdomain", signup: { subdomain: "admin" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/already taken/, response.body)
  end

  test "validate flags out-of-range seats" do
    post validate_signups_path, params: { field: "seats", signup: { seats: 0 } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "create succeeds with valid data" do
    post signups_path, params: { signup: { workspace_name: "Acme", subdomain: "acme", email: "a@b.com", seats: 4 } }
    assert_response :success
    assert_match(/is ready/, response.body)
  end

  test "create re-renders the form with a 422 when invalid" do
    post signups_path, params: { signup: { workspace_name: "", subdomain: "admin", email: "bad", seats: 0 } }
    assert_response :unprocessable_entity
    assert_match "signup_form", response.body
  end
end
