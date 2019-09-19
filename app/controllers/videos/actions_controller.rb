module Videos
  class ActionsController < BaseVideosController
    def update
      check_then do |video|
        @count = 0

        if params[:id] == 'like'
          @count = video.upvote(current_user, params[:incr])
        elsif params[:id] == 'dislike'
          @count = video.downvote(current_user, params[:incr])
        elsif params[:id] == 'star'
          @count = video.star(current_user)
        end

        return render json: {
          count: @count
        }
      end
    end
  end
end
