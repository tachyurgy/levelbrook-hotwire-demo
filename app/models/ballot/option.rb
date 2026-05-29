class Ballot::Option < ApplicationRecord
  belongs_to :poll, touch: true

  validates :label, presence: true

  # Share of the poll's total, for the CSS bar width. Server-computed so the
  # morph just animates the width — no charting library.
  def share(total)
    total.zero? ? 0 : ((votes_count.to_f / total) * 100).round
  end
end
