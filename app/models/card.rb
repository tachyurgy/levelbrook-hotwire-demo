class Card < ApplicationRecord
  belongs_to :column, touch: true

  has_one :board, through: :column

  validates :title, presence: true

  scope :ordered, -> { order(:position) }

  # Move this card to `target_column` at `target_position`, renumbering the
  # affected columns so positions stay dense and deterministic. Wrapped in a
  # transaction; the `touch: true` on the column association bubbles up to the
  # board, which broadcasts a refresh to every connected browser.
  def move_to!(target_column, target_position)
    transaction do
      source_column = column

      if source_column == target_column
        reorder_within(target_column, target_position)
      else
        update!(column: target_column)
        reorder_within(target_column, target_position)
        renumber(source_column)
      end
    end
  end

  private
    def reorder_within(target_column, target_position)
      others = target_column.cards.where.not(id: id).ordered.to_a
      target_position = target_position.to_i.clamp(0, others.size)
      others.insert(target_position, self)
      others.each_with_index do |card, index|
        card.update_columns(position: index) if card.position != index
      end
    end

    def renumber(column)
      column.cards.ordered.each_with_index do |card, index|
        card.update_columns(position: index) if card.position != index
      end
    end
end
