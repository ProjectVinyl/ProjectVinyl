module Admin
  module Videos
    class FeaturedVideosController < BaseVideosAdminController
      def update
        check_then do |video|
          Video.where(featured: true).each do |v|
            v.featured = false
            v.save
            v.update_index(defer: true)
          end

          video.featured = !video.featured
          video.add_tag('featured video') if video.featured
          video.save
          video.update_index(defer: true)

          render json: {
            added: video.featured
          }
        end
      end
    end
  end
end
