require "test_helper"

class Pulse::DashboardControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup { Pulse.seed! }

  test "the dashboard renders successfully" do
    get pulse_root_path
    assert_response :success
    assert_match "Service health", response.body
  end

  test "visiting the dashboard kicks off the always-on ticker" do
    assert_enqueued_with(job: Pulse::TickJob) do
      get pulse_root_path
    end
  end
end
