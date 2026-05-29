class Ballot::Room < ApplicationRecord
  has_many :polls, -> { order(:position) }, dependent: :destroy
  has_many :questions, -> { order(upvotes_count: :desc, created_at: :asc) }, dependent: :destroy

  validates :name, :slug, presence: true

  # Any vote or new/upvoted question touches the room, firing a single
  # page-refresh broadcast that morphs every connected client's tallies and
  # question order — no hand-targeted streams.
  broadcasts_refreshes

  def to_param = slug
end
