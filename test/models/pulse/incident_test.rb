require "test_helper"

class Pulse::IncidentTest < ActiveSupport::TestCase
  test "severity_style maps known severities" do
    assert_equal "bg-rose-100 text-rose-700",  Pulse::Incident.new(severity: "sev1").severity_style
    assert_equal "bg-amber-100 text-amber-800", Pulse::Incident.new(severity: "sev2").severity_style
    assert_equal "bg-slate-100 text-slate-700", Pulse::Incident.new(severity: "sev3").severity_style
  end

  test "severity_style falls back to the sev3 style for an unknown severity" do
    assert_equal "bg-slate-100 text-slate-700", Pulse::Incident.new(severity: "sev9").severity_style
  end

  test "resolved? is true only for the resolved status" do
    assert Pulse::Incident.new(status: "resolved").resolved?
    assert_not Pulse::Incident.new(status: "open").resolved?
    assert_not Pulse::Incident.new(status: "ack").resolved?
  end

  test "STATUSES lists the allowed statuses" do
    assert_equal %w[open ack resolved], Pulse::Incident::STATUSES
  end

  test "requires a title" do
    assert_not Pulse::Incident.new(title: "").valid?
    assert Pulse::Incident.new(title: "Outage").valid?
  end
end
