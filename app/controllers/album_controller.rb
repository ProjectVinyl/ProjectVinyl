class AlbumController < ApplicationController
  def view
    if @album = Album.where(id: params[:id].split(/-/)[0]).first
      @items = @album.album_items.order(:index)
      @modificationsAllowed = session[:current_user_id] == @album.artist.id
    end
  end
end
