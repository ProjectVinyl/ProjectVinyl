module Assets
  module Videos
    class CoversController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover.png' if !(video && video.hidden)
          return redirect_to '/images/default-cover-g.png' if !special_access?
          return serve_direct video.cover_path, 'image/png'
        end
      end
    end
  end
end
