class Grid::SheetsController < ApplicationController
  before_action :set_sheet, only: %i[show reset]

  def index
    sheets = Grid::Sheet.order(:id)
    redirect_to grid_sheet_path(sheets.first) if sheets.any?
  end

  def show
    @rows = @sheet.rows
  end

  def reset
    slug = @sheet.slug
    Grid::Sheet.destroy_all
    Grid.seed!
    redirect_to grid_sheet_path(Grid::Sheet.find_by(slug: slug) || Grid::Sheet.first),
      notice: "Sheet reset to the demo state."
  end

  private

  def set_sheet
    @sheet = Grid::Sheet.find_by!(slug: params[:slug])
  end
end
