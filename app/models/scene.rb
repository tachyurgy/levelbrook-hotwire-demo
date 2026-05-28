class Scene < ApplicationRecord
  belongs_to :story
  has_many :choices, -> { order(:position) }, dependent: :destroy

  validates :key, presence: true, uniqueness: { scope: :story_id }
  validates :heading, :body, presence: true

  MOODS = %w[calm tense eerie hopeful grim].freeze

  def ending? = ending
end
