require "test_helper"

class Pulse::DashboardControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Pulse.seed!
  end

  test "the dashboard renders successfully" do
    get pulse_root_path
    assert_response :success
  end

  test "simulate enqueues the sample job and returns no_content" do
    assert_enqueued_with(job: Pulse::SampleJob) do
      post pulse_simulate_path
    end
    assert_response :no_content
  end
end
