module Albums
  class ItemsController < BaseAlbumsController

    def create
      check_then_with(Album) do |album|
        return head :not_found if !(video = Video.where(id: params[:videoId]).first)
        album.add_item(video)
      end
    end

    def update
      check_then_with(AlbumItem) do |item|
        item.move(params[:index].to_i)
      end
    end

    def destroy
      check_then_with(AlbumItem) do |item|
        item.destroy
      end
    end

    def index
      return head :not_found if !(@album = Album.where(id: params[:id]).first)
      @items = @album.ordered(@album.album_items.includes(:direct_user))
      @modifications_allowed = user_signed_in? && @album.owned_by(current_user)

      render_pagination 'album/item', @items, params[:page].to_i, 50, false
    end
  end
end
