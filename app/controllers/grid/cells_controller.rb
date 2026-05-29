# Editing a cell saves the value and touches the sheet; broadcasts_refreshes
# then morphs the recomputed formula cells (row Total + grand total) onto every
# client. Response is 204 — the morph carries all the UI updates.
class Grid::CellsController < ApplicationController
  def update
    row = Grid::Row.find(params[:id])
    row.assign_cell(params[:field].to_s, params.dig(:row, params[:field]))
    head :no_content
  end
end
