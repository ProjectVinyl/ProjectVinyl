module Comments
  class LikesController < BaseCommentsController
    def update
      check_then do |comment|
        render json: {
          count: comment.upvote(current_user, params[:incr])
        }
      end
    end
  end
end