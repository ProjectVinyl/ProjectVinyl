module Videos
  class AddsController < ApplicationController
    def update
      if !(video = Video.where(id: params[:video_id]).first)
        return head :not_found
      end

      if !(album = Album.where(id: params[:item]).first)
        return head :not_found
      end

      render json: {
        added: album.toggle(video)
      }
    end
  end
end
