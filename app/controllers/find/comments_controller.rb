module Find
  class CommentsController < ApplicationController
    def index
      return head :not_found if !(comment = Comment.where(id: params[:id]).first)
      render partial: 'comments/comment', locals: {
        comment: comment,
        indirect: false
      }
    end
  end
end
