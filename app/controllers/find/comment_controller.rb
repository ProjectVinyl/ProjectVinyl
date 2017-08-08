module Find
  class CommentController < ApplicationController
    def find
      if !(comment = Comment.where(id: params[:id]).first)
        return head 404
      end
      
      render partial: 'comment/comment', locals: {
        comment: comment,
        indirect: false
      }
    end
  end
end
