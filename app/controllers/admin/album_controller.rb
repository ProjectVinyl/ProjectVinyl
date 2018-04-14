module Admin
  class AlbumController < BaseAdminController
    def show
      if !current_user.is_staff?
        return render_access_denied
      end
      
      if !(@album = Album.find(params[:id]))
        return render_error(
          title: 'Nothing to see here!',
          description: 'This album appears to have been moved or deleted.'
        )
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { title: 'Albums' },
          { link: @album.link, title: @album.id }
        ],
        title: @album.title
      }
      
      @modifications_allowed = true
      @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), 0, 50, false)
      @user = @album.user
    end
    
    def feature
      if !current_user.is_staff?
        return head 401
      end
      
      if !(album = Album.where(id: params[:album_id]).first)
        return head :not_found
      end
      
      Album.where('featured > 0').update_all(featured: 0)
      album.featured = album.featured > 0 ? 0 : 1
      if album.featured > 0
        album.save
      end
      
      render json: {
        added: () > 0
      }
    end
  end
end
