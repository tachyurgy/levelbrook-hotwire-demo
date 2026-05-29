class Message < ApplicationRecord
  belongs_to :channel
  belongs_to :member, optional: true

  validates :body, presence: true

  EMOJI = %w[👍 🎉 🚀 ❤️].freeze

  # Append-feed pattern (not refresh): each new message streams onto the end
  # of the channel's message list for every subscribed client.
  after_create_commit do
    broadcast_append_to channel, target: "messages", partial: "messages/message"
  end

  # A reaction is a surgical update, not an append — replace just this message
  # for everyone subscribed to the channel.
  after_update_commit do
    broadcast_replace_to channel, target: ActionView::RecordIdentifier.dom_id(self),
      partial: "messages/message"
  end

  def reactions_hash
    JSON.parse(reactions.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def add_reaction(emoji)
    return unless EMOJI.include?(emoji)
    counts = reactions_hash
    counts[emoji] = (counts[emoji] || 0) + 1
    update(reactions: counts.to_json)
  end
end
