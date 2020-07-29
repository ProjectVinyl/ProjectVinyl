module Admin
  module Albums
    class FeaturesController < BaseAdminController
      def update
        return head 401 if !current_user.is_staff?
        return head :not_found if !(album = Album.where(id: params[:album_id]).first)

        Album.where('featured > 0').update_all(featured: 0)
        album.featured = album.featured > 0 ? 0 : 1
        album.save if album.featured > 0

        render json: {
          added: album.featured > 0
        }
      end
    end
  end
end
