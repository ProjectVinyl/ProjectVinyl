module Comments
  class BaseCommentsController < ApplicationController
    protected
    def check_then
      return head :unauthorized if !user_signed_in?
      return head :not_found if !(comment = Comment.where(id: params[:id] || params[:comment_id]).first)
      yield(comment)
    end
  end
end