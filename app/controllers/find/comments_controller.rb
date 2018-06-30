module Find
  class CommentsController < ApplicationController
    def find
      if !(comment = Comment.where(id: params[:id]).first)
        return head :not_found
      end
      
      render partial: 'comments/comment', locals: {
        comment: comment,
        indirect: false
      }
    end
  end
end
