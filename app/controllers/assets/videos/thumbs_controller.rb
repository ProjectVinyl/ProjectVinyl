module Assets
  module Videos
    class ThumbsController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover-small.png' if !(video && video.hidden)
          return redirect_to '/images/default-cover-small-g.png' if !special_access?
          return serve_direct video.tiny_cover_path, 'image/png'
        end
      end
    end
  end
end
