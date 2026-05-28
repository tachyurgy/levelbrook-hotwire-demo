class Board < ApplicationRecord
  # Turbo 8: any commit broadcasts a `<turbo-stream action="refresh">` to
  # subscribers of `turbo_stream_from @board`. Connected browsers re-fetch the
  # current page and morph the DOM, so the whole board stays in sync with zero
  # hand-written broadcast plumbing. This is the Fizzy default pattern.
  broadcasts_refreshes

  has_many :columns, -> { order(:position) }, dependent: :destroy
  has_many :cards, through: :columns

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param = slug
end
