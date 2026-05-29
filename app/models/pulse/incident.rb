class Pulse::Incident < ApplicationRecord
  belongs_to :service, class_name: "Pulse::Service", optional: true

  validates :title, presence: true

  SEVERITY_STYLES = {
    "sev1" => "bg-rose-100 text-rose-700",
    "sev2" => "bg-amber-100 text-amber-800",
    "sev3" => "bg-slate-100 text-slate-700"
  }.freeze

  STATUSES = %w[open ack resolved].freeze

  def severity_style = SEVERITY_STYLES.fetch(severity, SEVERITY_STYLES["sev3"])
  def resolved? = status == "resolved"
end
