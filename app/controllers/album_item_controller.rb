class AlbumItemController < ApplicationController
  def index
    if @album = Album.where(id: params[:id]).first
      @page = params[:page].to_i
      @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), @page, 50, false)
      @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
      render json: {
        content: render_to_string(partial: '/album/item', collection: @items.records),
        pages: @items.pages,
        page: @items.page
      }
    end
  end
  
  def create
    if user_signed_in?
      if album = Album.where(id: params[:id]).first
        if album.owned_by(current_user)
          if video = Video.where(id: params[:videoId]).first
            album.add_item(video)
            return head 200
          end
        end
      end
    end
    head 401
  end
  
  def update
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.owned_by(current_user)
          item.move(params[:index].to_i)
          return head 200
        end
      end
    end
    head 401
  end
  
  def destroy
    if user_signed_in?
      if item = AlbumItem.where(id: params[:id]).first
        if item.album.owned_by(current_user)
          item.remove_self
          return head 200
        end
      end
    end
    head 401
  end
  
  def toggle
    if user_signed_in?
      if (album = Album.where(id: params[:item]).first) && album.owned_by(current_user)
        if video = Video.where(id: params[:id]).first
          return render json: { added: album.toggle(video) }
        end
      end
    end
    head 401
  end
end
