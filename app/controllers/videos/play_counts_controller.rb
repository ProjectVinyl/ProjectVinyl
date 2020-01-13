module Videos
  class PlayCountsController < BaseVideosController
    def update
      if !(video = Video.where(id: params[:video_id]).first)
        return head :not_found
      end

      video.play_count += 1
      video.compute_hotness.save

      return render json: {
        count: video.play_count
      }
    end
  end
end
