module Videos
  class ActionsController < BaseVideosController
    def update
      check_then do |video|
        @count = 0
        @count = video.upvote(current_user, params[:incr]) if params[:id] == 'like'
        @count = video.downvote(current_user, params[:incr]) if params[:id] == 'dislike'
        @count = video.star(current_user) if params[:id] == 'star'

        return render json: {
          count: @count,
          added: params[:id] == 'star' && video.faved?(current_user)
        }
      end
    end
  end
end
