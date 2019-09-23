module Comments
  class BaseCommentsController < ApplicationController
    protected
    def check_then
      if !user_signed_in?
        return head :unauthorized
      end

      if !(comment = Comment.where(id: params[:id] || params[:comment_id]).first)
        return head :not_found
      end

      yield(comment)
    end
  end
end