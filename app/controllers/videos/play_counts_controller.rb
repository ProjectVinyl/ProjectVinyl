module Videos
  class PlayCountsController < BaseVideosController
    def update
      return head :not_found if !(video = Video.where(id: params[:video_id], draft: false).first)

      video.play_count += 1
      video.compute_hotness.save

      if user_signed_in?
        user = current_user

        if (entry = user.watch_histories.where(video: video).first)
          entry.touch
        else
          entry = user.watch_histories.create(video: video)
        end

        entry.save
      end

      render json: {
        count: video.play_count
      }
    end
  end
end
