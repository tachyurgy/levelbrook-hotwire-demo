require "test_helper"

# Smoke coverage for the three-app demo: the gallery front door plus the two
# non-workspace apps (Relay AI streaming and the Forge gem playgrounds).
# Workspace's flow is covered in depth by WorkspaceFlowTest.
class ShowcaseAppsTest < ActionDispatch::IntegrationTest
  setup do
    @member = Member.create!(name: "Eng Lead")
  end

  # --- Gallery ---------------------------------------------------------
  test "gallery lists the three apps with entry links" do
    get root_path
    assert_response :success
    Showcase.all.each { |app| assert_match app.name, response.body }
    assert_equal %i[workspace relay forge], Showcase.all.map(&:key)
  end

  # --- Relay (AI streaming) -------------------------------------------
  test "relay chat page renders its prompt form" do
    get relay_root_path
    assert_response :success
    assert_select "form"
  end

  # --- Forge (gem playgrounds) ----------------------------------------
  test "forge root redirects to the picoglob bench" do
    get forge_root_path
    assert_redirected_to forge_picoglob_path
  end

  test "forge picoglob bench compiles a glob and reports matches" do
    get forge_picoglob_path, params: { pattern: "app/**/*.rb", subject: "app/models/user.rb\nREADME.md" }
    assert_response :success
    assert_match "app/models/user.rb", response.body
  end

  test "forge fzy bench ranks a fuzzy query" do
    get forge_fzy_path, params: { query: "usr", subject: "app/models/user.rb\nconfig/routes.rb" }
    assert_response :success
  end
end
