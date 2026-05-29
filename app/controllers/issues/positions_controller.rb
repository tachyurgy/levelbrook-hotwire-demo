module Issues
  # Thin endpoint hit by the SortableJS Stimulus controller on drop.
  # It reorders the destination column server-side; the Project's
  # broadcasts_refreshes then morphs every connected board.
  class PositionsController < ApplicationController
    def update
      issue = Issue.find(params[:issue_id])
      column = Column.find(params[:column_id])
      position = params[:position].to_i

      Issue.transaction do
        issue.update!(column: column)
        reorder(column, issue, position)
      end

      head :no_content
    end

    private

    # Persist the dropped order exactly as the DOM now shows it.
    def reorder(column, moved_issue, target_index)
      others = column.issues.where.not(id: moved_issue.id).order(:position).to_a
      # Clamp so an out-of-range drop index appends instead of padding the
      # array with nils (Array#insert grows the array with nils past the end).
      index = target_index.clamp(0, others.size)
      others.insert(index, moved_issue)
      others.each_with_index do |issue, index|
        issue.update_column(:position, index) if issue.position != index
      end
    end
  end
end
