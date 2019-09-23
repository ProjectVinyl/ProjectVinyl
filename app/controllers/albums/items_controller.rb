module Albums
  class ItemsController < BaseAlbumsController

    def create
      check_then_with(Album) do |album|
        if !(video = Video.where(id: params[:videoId]).first)
          return head :not_found
        end

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
      if !(@album = Album.where(id: params[:id]).first)
        return head :not_found
      end

      @items = @album.ordered(@album.album_items.includes(:direct_user))
      @modifications_allowed = user_signed_in? && @album.owned_by(current_user)

      render_pagination 'album/item', @items, params[:page].to_i, 50, false
    end
  end
end