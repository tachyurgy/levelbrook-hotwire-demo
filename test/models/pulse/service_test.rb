require "test_helper"

class Pulse::ServiceTest < ActiveSupport::TestCase
  test "sample_points parses the JSON samples" do
    service = Pulse::Service.new(name: "API", slug: "api", samples: [ 1, 2, 3 ].to_json)
    assert_equal [ 1, 2, 3 ], service.sample_points
  end

  test "sample_points returns an empty array on bad JSON" do
    service = Pulse::Service.new(name: "API", slug: "api", samples: "not json{")
    assert_equal [], service.sample_points
  end

  test "push_sample keeps a rolling window of the given size" do
    service = Pulse::Service.new(name: "API", slug: "api", samples: (1..24).to_a.to_json)
    service.push_sample(99, window: 24)
    points = service.sample_points
    assert_equal 24, points.size
    assert_equal 99, points.last
    assert_equal 2, points.first
  end

  test "style falls back to healthy for an unknown status" do
    assert_equal Pulse::Service::STATUS_STYLES["healthy"],
      Pulse::Service.new(name: "x", slug: "x", status: "mystery").style
    assert_equal Pulse::Service::STATUS_STYLES["down"],
      Pulse::Service.new(name: "x", slug: "x", status: "down").style
  end

  test "to_param is the slug" do
    assert_equal "api-gateway", Pulse::Service.new(slug: "api-gateway").to_param
  end

  test "requires a name and slug" do
    assert_not Pulse::Service.new(name: "", slug: "x").valid?
    assert_not Pulse::Service.new(name: "x", slug: "").valid?
  end
end
