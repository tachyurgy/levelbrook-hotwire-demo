class Message < ApplicationRecord
  belongs_to :channel
  belongs_to :member, optional: true

  validates :body, presence: true

  # Append-feed pattern (not refresh): each new message streams onto the end
  # of the channel's message list for every subscribed client.
  after_create_commit do
    broadcast_append_to channel, target: "messages", partial: "messages/message"
  end
end
