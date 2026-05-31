class ChannelsController < ApplicationController
  # When the conversation frame asks for a channel, render just the frame — no
  # shell, no <head>. Tiny response, instant swap. A full page load (refresh,
  # deep link, arriving from another app) still renders the whole layout.
  layout -> { turbo_frame_request? ? false : "application" }

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
