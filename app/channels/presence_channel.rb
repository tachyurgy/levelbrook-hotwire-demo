# Lightweight anonymous presence for the public Kanban demo. Each browser tab
# that connects bumps a per-board viewer count; on disconnect it drops. The new
# count is broadcast to everyone via a Turbo Stream that replaces the small
# "N viewing" badge — mirroring Campfire's presence idiom, minus the
# authenticated membership model (this board is public and identity-free).
class PresenceChannel < ApplicationCable::Channel
  @counts = Hash.new(0)
  @mutex  = Mutex.new

  class << self
    attr_reader :counts, :mutex

    def increment(board_id)
      mutex.synchronize { counts[board_id] += 1 }
    end

    def decrement(board_id)
      mutex.synchronize { counts[board_id] = [ counts[board_id] - 1, 0 ].max }
    end

    def count_for(board_id)
      mutex.synchronize { counts[board_id] }
    end
  end

  def subscribed
    @board = Board.find(params[:board_id])
    stream_for @board
    self.class.increment(@board.id)
    broadcast_count
  end

  def unsubscribed
    return unless @board

    self.class.decrement(@board.id)
    broadcast_count
  end

  private
    def broadcast_count
      count = self.class.count_for(@board.id)
      html = ApplicationController.render(
        partial: "boards/presence",
        locals: { count: count }
      )
      PresenceChannel.broadcast_to(@board, html)
    end
end
