class PagesController < ApplicationController
  def home
    @projects = Project.all
    @channels = Channel.all
    @members = Member.order(:id)
  end
end
