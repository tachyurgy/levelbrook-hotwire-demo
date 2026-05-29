class Pulse::Service < ApplicationRecord
  has_many :incidents, dependent: :nullify

  validates :name, :slug, presence: true

  STATUS_STYLES = {
    "healthy"   => { dot: "bg-emerald-500", text: "text-emerald-700", label: "Healthy" },
    "degraded"  => { dot: "bg-amber-500",   text: "text-amber-700",   label: "Degraded" },
    "deploying" => { dot: "bg-indigo-500",  text: "text-indigo-700",  label: "Deploying" },
    "down"      => { dot: "bg-rose-500",     text: "text-rose-700",    label: "Down" }
  }.freeze

  def to_param = slug
  def style = STATUS_STYLES.fetch(status, STATUS_STYLES["healthy"])

  def sample_points
    JSON.parse(samples)
  rescue JSON::ParserError
    []
  end

  # Push a new latency sample, keeping a rolling window.
  def push_sample(value, window: 24)
    points = (sample_points + [ value ]).last(window)
    self.samples = points.to_json
  end
end
