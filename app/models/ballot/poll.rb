class Ballot::Poll < ApplicationRecord
  belongs_to :room, touch: true
  has_many :options, -> { order(:position) }, dependent: :destroy

  validates :question, presence: true

  def total_votes = options.sum(&:votes_count)
end
