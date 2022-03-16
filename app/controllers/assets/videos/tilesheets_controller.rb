module Assets
  module Videos
    class TilesheetsController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover.png' if !(video && video.hidden)
          return redirect_to '/images/default-cover-g.png' if !special_access?
          return serve_direct video.frames_path + (params[:sheet_name] + '.jpg'), 'image/jpg'
        end
      end
    end
  end
end
