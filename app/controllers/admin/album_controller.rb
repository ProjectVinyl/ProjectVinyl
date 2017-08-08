module Admin
  class AlbumController < ApplicationController
    before_action :authenticate_user!
    
    def view
      if !current_user.is_staff?
        return render 'layouts/error', locals: {
          title: 'Access Denied',
          description: "You can't do that right now."
        }
      end
      
      if !(@album = Album.find(params[:id]))
        return render 'layouts/error', locals: {
          title: 'Nothing to see here!',
          description: 'This album appears to have been moved or deleted.'
        }
      end
      
      @modifications_allowed = true
      @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), 0, 50, false)
      @user = @album.user
    end
    
    def toggle_featured
      if !current_user.is_staff?
        return head 401
      end
      
      if !(album = Album.where(id: params[:id]).first)
        return head 404
      end
      
      Album.where('featured > 0').update_all(featured: 0)
      album.featured = album.featured > 0 ? 0 : 1
      album.save
      render json: {
        added: album.featured > 0
      }
    end
  end
end
