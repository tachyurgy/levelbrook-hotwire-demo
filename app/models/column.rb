class Column < ApplicationRecord
  # Touching the board on any column/card change is what triggers the board's
  # `broadcasts_refreshes`, so a move in one browser morphs every other browser.
  belongs_to :board, touch: true

  has_many :cards, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true

  # Tailwind accent tokens, resolved in the view helper. Keeping them on the
  # record (not hardcoded class strings) keeps the column reusable/recolorable.
  ACCENTS = %w[slate sky violet amber emerald rose].freeze
end
