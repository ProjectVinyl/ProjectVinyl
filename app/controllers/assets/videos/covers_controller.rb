module Assets
  module Videos
    class CoversController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover.svg' if !(video && video.visible_to?(current_user))
          return redirect_to '/images/default-cover-g.svg' if !special_access?
          return serve_direct video.cover_path, 'image/png', fallback: '/images/default-cover.svg'
        end
      end
    end
  end
end
