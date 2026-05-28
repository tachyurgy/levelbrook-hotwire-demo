class PagesController < ApplicationController
  def home
    @stories = Story.all
  end
end
