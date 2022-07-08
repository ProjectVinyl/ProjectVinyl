module Assets
  module Videos
    class TilesheetsController < BaseAssetsController
      def show
        with_video do |video|
          return redirect_to '/images/default-cover.svg' if !(video && video.visible_to?(current_user))
          return redirect_to '/images/default-cover-g.svg' if !special_access?
          return serve_direct video.frames_path + (params[:sheet_name] + '.jpg'), 'image/jpg', fallback: '/images/default-cover.svg'
        end
      end
    end
  end
end
