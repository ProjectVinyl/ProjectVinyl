module Videos
  class PlayCountsController < BaseVideosController
    def update
      if !(video = Video.where(id: params[:video_id]).first)
        return head :not_found
      end

      video.play_count += 1
      video.compute_hotness.save

      if user_signed_in?
        user = current_user
        if WatchHistory
          .where(user: user, video: video)
          .most_recent
          .pluck(:video_id)
          .first != video.id
          WatchHistory.create(user: user, video: video)
        end
      end

      return render json: {
        count: video.play_count
      }
    end
  end
end
