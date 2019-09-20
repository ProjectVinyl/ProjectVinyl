module Albums
  class StarsController < BaseAlbumsController
    def show
      check_and do
        @user = current_user
        @album = current_user.stars
        
        @records = @album.ordered(@album.album_items.includes(:direct_user))
        @items = Pagination.paginate(@records, 0, 50, false)
        @modifications_allowed = true
        
        render template: 'albums/show'
      end
    end
  end
end
