class AlbumItemController < ApplicationController
  def index
    if !(@album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    @page = params[:page].to_i
    @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), @page, 50, false)
    @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
    
    render_pagination 'album/item', @items
  end
  
  def create
    if !user_signed_in?
      return head 401
    end
    
    if !(album = Album.where(id: params[:id]).first)
      return head 404
    end
    
    if !album.owned_by(current_user)
      return head 401
    end
    
    if !(video = Video.where(id: params[:videoId]).first)
      return head 404
    end
    
    album.add_item(video)
    head 200
  end
  
  def update
    if !user_signed_in?
      return head 401
    end
    if !(item = AlbumItem.where(id: params[:id]).first)
      return head 404
    end
    
    if !item.album.owned_by(current_user)
      return head 401
    end
    
    item.move(params[:index].to_i)
    head 200
  end
  
  def destroy
    if !user_signed_in?
      return head 401
    end
    
    if !(item = AlbumItem.where(id: params[:id]).first)
      return head 404
    end
    
    if item.album.owned_by(current_user)
      return head 401
    end
    
    item.remove_self
    head 200
  end
  
  def toggle
    if !user_signed_in?
      return head 401
    end
    
    if !(album = Album.where(id: params[:item]).first) || !album.owned_by(current_user)
      return head 401
    end
    
    if !(video = Video.where(id: params[:id]).first)
      return head 404
    end
    
    render json: {
      added: album.toggle(video)
    }
  end
end
