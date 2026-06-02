# A player-submitted flag that a LinguaGuessr audio clip is bad (no sound, dead
# air, garbled, or mislabeled). Written by the JSON API at
# Api::V1::BadAudioReportsController; this app just durably records them so the
# corpus pipeline can review/prune the offending clips later.
class BadAudioReport < ApplicationRecord
  STATUSES = %w[open reviewed dismissed].freeze

  validates :clip_id, presence: true, length: { maximum: 200 }
  validates :reason,  length: { maximum: 500 }, allow_blank: true
  validates :status,  inclusion: { in: STATUSES }

  # Defensive caps so a noisy/abusive client can't bloat a row.
  before_validation do
    self.status ||= "open"
    self.clip_url   = clip_url.to_s.first(500).presence
    self.page_url   = page_url.to_s.first(500).presence
    self.user_agent = user_agent.to_s.first(300).presence
    self.lang       = lang.to_s.first(20).presence
    self.lang_name  = lang_name.to_s.first(80).presence
    self.reason     = reason.to_s.first(500).presence
  end

  scope :open, -> { where(status: "open") }
end
