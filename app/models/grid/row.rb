class Grid::Row < ApplicationRecord
  belongs_to :sheet, touch: true

  EDITABLE = %w[label category qty unit_price].freeze
  NUMERIC  = %w[qty unit_price].freeze

  validates :label, presence: true
  validates :qty, :unit_price, numericality: { greater_than_or_equal_to: 0 }

  # The formula cell: server-computed, never stored.
  def total = qty * unit_price

  def assign_cell(field, value)
    return unless EDITABLE.include?(field)
    value = value.to_s.gsub(/[^\d]/, "").to_i if NUMERIC.include?(field)
    update(field => value)
  end
end
