class AlbumItemController < ApplicationController
  def index
    if !(@album = Album.where(id: params[:id]).first)
      return head :not_found
    end
    
    @items = @album.ordered(@album.album_items.includes(:direct_user))
    @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
    
    render_pagination 'album/item', @items, params[:page].to_i, 50, false
  end
  
  def create
    check_then(Album) do |album|
      if !(video = Video.where(id: params[:videoId]).first)
        return head :not_found
      end
      
      album.add_item(video)
    end
  end
  
  def update
    check_then(AlbumItem) do |item|
      item.move(params[:index].to_i)
    end
  end
  
  def destroy
    check_then(AlbumItem) do |item|
      item.remove_self
    end
  end
  
  def toggle
    if !(video = Video.where(id: params[:id]).first)
      return head :not_found
    end
    
    render json: {
      added: album.toggle(video)
    }
  end
  
  private
  def check_then(table)
    if !user_signed_in?
      return head 401
    end
    
    if !(item = table.where(id: params[:id]).first)
      return head :not_found
    end
    
    if !item.owned_by(current_user)
      return head 401
    end
    
    yield(item)
    head :ok
  end
end
