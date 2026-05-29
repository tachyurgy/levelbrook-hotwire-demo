# Relays ephemeral "X is typing…" events between clients in a channel.
# Nothing is persisted; this is raw cable JSON, not DOM-over-the-wire.
class TypingChannel < ApplicationCable::Channel
  def subscribed
    @slug = params[:slug]
    return reject if @slug.blank?

    stream_from stream_name
  end

  def start(_data = {})
    relay("start")
  end

  def stop(_data = {})
    relay("stop")
  end

  private

  def stream_name = "typing:#{@slug}"

  def relay(action)
    ActionCable.server.broadcast(stream_name, { action: action, name: connection.member_name })
  end
end
