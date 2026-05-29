# Optimistic emoji reactions. The bump is applied client-side immediately
# (emoji_react_controller); here we persist it and the model broadcast_replaces
# the message for every subscriber, reconciling the count.
class ReactionsController < ApplicationController
  def create
    channel = Channel.find_by!(slug: params[:channel_slug])
    message = channel.messages.find(params[:message_id])
    message.add_reaction(params[:emoji].to_s)
    head :no_content
  end
end
