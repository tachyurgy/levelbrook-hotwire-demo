class ChannelsController < ApplicationController
  def index
    @channels = Channel.all
    redirect_to channel_path(@channels.first) if @channels.any?
  end

  def show
    @channel = Channel.find_by!(slug: params[:slug])
    @channels = Channel.all
    @messages = @channel.messages.includes(:member).last(50)
    @members = Member.order(:id)
  end
end
