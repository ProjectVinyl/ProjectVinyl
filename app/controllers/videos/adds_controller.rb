module Videos
  class AddsController < ApplicationController
    def update
      return head :not_found if !(video = Video.where(id: params[:video_id]).first)
      return head :not_found if !(album = Album.where(id: params[:item]).first)
      render json: {
        added: album.video_set.toggle(video)
      }
    end

    def show
      @video = Video.where(id: params[:video_id]).first
      render partial: 'videos/adds/actions', formats: [:html] if params[:format] == 'json'
    end
  end
end
