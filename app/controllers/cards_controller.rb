class CardsController < ApplicationController
  before_action :set_card, only: [ :update, :destroy, :move ]

  def create
    column = Column.find(params[:column_id])
    @card = column.cards.create!(
      title: params.dig(:card, :title).presence || "New card",
      position: column.cards.count
    )
    # The card's touch -> column -> board chain broadcasts a refresh; the
    # creating browser also gets it, so we just bounce back to the board.
    redirect_to board_path
  end

  def update
    @card.update!(card_params)
    redirect_to board_path
  end

  def destroy
    @card.destroy!
    redirect_to board_path
  end

  # Persist a drag-and-drop move. Called by the drag_and_drop Stimulus
  # controller via fetch; the model renumbers positions and the board's
  # broadcasts_refreshes pushes the new layout to every connected browser.
  def move
    column = Column.find(params[:column_id])
    @card.move_to!(column, params[:position].to_i)
    head :ok
  end

  private
    def set_card
      @card = Card.find(params[:id])
    end

    def card_params
      params.require(:card).permit(:title, :body, :assignee, :tag)
    end
end
