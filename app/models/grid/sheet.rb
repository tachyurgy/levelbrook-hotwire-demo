class Grid::Sheet < ApplicationRecord
  has_many :rows, -> { order(:position) }, dependent: :destroy

  validates :name, :slug, presence: true

  # A cell edit touches the sheet, firing one refresh broadcast that morphs the
  # recomputed formula cells (row totals + grand total) onto every client.
  broadcasts_refreshes

  def to_param = slug
  def grand_total = rows.sum(&:total)
end
