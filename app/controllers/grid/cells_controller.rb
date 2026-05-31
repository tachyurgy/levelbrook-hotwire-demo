# Saving a cell touches the sheet; broadcasts_refreshes then morphs the
# recomputed formula cells (row Total + grand total) onto every OTHER open tab.
# We also redirect back to the sheet so THIS tab re-renders and morphs — Turbo
# suppresses a refresh broadcast on the tab that triggered it (request-id match),
# so without the redirect the editing tab would never see its own totals update.
class Grid::CellsController < ApplicationController
  def update
    row = Grid::Row.find(params[:id])
    row.assign_cell(params[:field].to_s, params.dig(:row, params[:field]))
    redirect_to grid_sheet_path(row.sheet), status: :see_other
  end
end
