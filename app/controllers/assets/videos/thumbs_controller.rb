module Assets
  module Videos
    class ThumbsController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover-small.svg' if !(video && video.visible_to?(current_user))
          return redirect_to '/images/default-cover-small-g.svg' if !special_access?
          return serve_direct video.tiny_cover_path, 'image/png', fallback: '/images/default-cover.svg'
        end
      end
    end
  end
end
