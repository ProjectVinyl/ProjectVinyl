module Admin
  module Albums
    class FeaturesController < BaseAdminController
      def update
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
          added: album.featured > 0
        }
      end
    end
  end
end
