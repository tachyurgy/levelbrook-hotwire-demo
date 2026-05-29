class MessagesController < ApplicationController
  def create
    @channel = Channel.find_by!(slug: params[:channel_slug])
    @message = @channel.messages.build(message_params.merge(member: current_member))

    if @message.save
      # Model append-broadcasts to every subscriber. Reset the composer locally.
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          "new_message", partial: "messages/form", locals: { channel: @channel }
        ) }
        format.html { redirect_to channel_path(@channel) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
