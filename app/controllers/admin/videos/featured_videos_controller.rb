module Admin
  module Videos
    class FeaturedVideosController < BaseVideosAdminController
      def update
        check_then do |video|
          Video.where(featured: true).update_all(featured: false)
          render json: {
            added: video.featured = !video.featured
          }

          if video.featured
            video.save
            video.add_tag('featured video')
          end
        end
      end
    end
  end
end
