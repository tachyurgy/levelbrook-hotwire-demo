class Spindle::AlbumsController < ApplicationController
  def index
    @albums = Spindle::Album.order(:position).includes(:tracks)
  end

  def show
    @album = Spindle::Album.find_by!(slug: params[:slug])
    @tracks = @album.tracks
  end
end
