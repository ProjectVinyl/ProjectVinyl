module Find
  class CommentController < ApplicationController
    def find
      if comment = Comment.where(id: params[:id]).first
        return render partial: '/thread/comment', locals: { comment: comment, indirect: false }
      end
      head 404
    end
  end
end
