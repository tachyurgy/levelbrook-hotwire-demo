require "test_helper"

class SignupTest < ActiveSupport::TestCase
  test "valid with good attributes" do
    signup = Signup.new(workspace_name: "Acme", subdomain: "acme", email: "a@b.com", seats: 5)
    assert signup.valid?, signup.errors.full_messages.to_sentence
  end

  test "rejects invalid email" do
    signup = Signup.new(workspace_name: "Acme", subdomain: "acme", email: "nope", seats: 5)
    assert_not signup.valid?
    assert signup.errors[:email].any?
  end

  test "rejects reserved subdomain" do
    signup = Signup.new(workspace_name: "Acme", subdomain: "admin", email: "a@b.com", seats: 5)
    assert_not signup.valid?
    assert_includes signup.errors[:subdomain], "is already taken"
  end

  test "rejects subdomain with invalid characters" do
    signup = Signup.new(workspace_name: "Acme", subdomain: "Bad Name", email: "a@b.com", seats: 5)
    assert_not signup.valid?
    assert signup.errors[:subdomain].any?
  end

  test "rejects out-of-range seats" do
    assert_not Signup.new(workspace_name: "Acme", subdomain: "acme", email: "a@b.com", seats: 0).valid?
    assert_not Signup.new(workspace_name: "Acme", subdomain: "acme", email: "a@b.com", seats: 9999).valid?
  end
end
