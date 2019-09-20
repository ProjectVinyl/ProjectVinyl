module Albums
  class ItemsController < BaseAlbumsController
    def index
      if !(@album = Album.where(id: params[:id]).first)
        return head :not_found
      end
      
      @items = @album.ordered(@album.album_items.includes(:direct_user))
      @modifications_allowed = user_signed_in? && @album.owned_by(current_user)
      
      render_pagination 'album/item', @items, params[:page].to_i, 50, false
    end
  end
end
