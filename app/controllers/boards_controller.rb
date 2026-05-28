class BoardsController < ApplicationController
  before_action :set_board

  def show
  end

  # Chromeless render used inside the side-by-side <iframe> on /board, so a
  # single visitor watches the realtime morph happen in the second pane.
  def embed
    render :embed, layout: "embed"
  end

  # Public demo safety valve: wipe the shared board back to its seeded state so
  # visitors can't permanently wreck it. The reseed touches the board, which
  # broadcasts a refresh to every connected browser.
  def reset
    BoardSeeder.reset!(@board)
    redirect_back fallback_location: board_path, notice: "Board reset to its starting state."
  end

  private
    def set_board
      @board = Board.includes(columns: :cards).first!
    end
end
