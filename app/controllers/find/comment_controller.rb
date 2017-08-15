module Find
  class CommentController < ApplicationController
    def find
      if !(comment = Comment.where(id: params[:id]).first)
        return head :not_found
      end
      
      render partial: 'comment/comment', locals: {
        comment: comment,
        indirect: false
      }
    end
  end
end
