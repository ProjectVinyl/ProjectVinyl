class AlbumController < ApplicationController
  def view
    if @album = Album.where(id: params[:id].split(/-/)[0]).first
      @items = @album.album_items.order(:index)
      @modificationsAllowed = session[:current_user_id] == @album.artist.id
    end
  end
  
  def starred
    if user_signed_in?
      @artist = Artist.where(id: current_user.artist_id).first
      @items = current_user.stars
    end
  end
end
