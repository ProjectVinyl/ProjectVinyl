module Assets
  module Videos
    class SourcesController < BaseAssetsController
      def show
        with_video do |video|
          return not_found if !(video && video.hidden)
          return forbidden if !special_access?
          return serve_direct video.video_path, video.mime
        end
      end
    end
  end
end
