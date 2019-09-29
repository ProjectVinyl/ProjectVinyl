module Assets
  module Videos
    class VideosController < BaseAssetsController
      def show
        with_video do |video|
          return not_found if !(video && video.hidden)
          return forbidden if !special_access?
          return serve_direct video.webm_path, 'video/webm'
        end
      end
    end
  end
end
