module Admin
  class ThreadController < ApplicationController
    def pin
      if user_signed_in? && current_user.is_staff?
        if thread = CommentThread.where(id: params[:id]).first
          thread.pinned = !thread.pinned
          thread.save
          render json: { added: thread.pinned }
          return
        end
      end
      head 401
    end

    def lock
      if user_signed_in? && current_user.is_contributor?
        if thread = CommentThread.where(id: params[:id]).first
          thread.locked = !thread.locked
          thread.save
          render json: { added: thread.locked }
          return
        end
      end
      head 401
    end
    
    def move
      if user_signed_in? && current_user.is_contributor?
        if thread = CommentThread.where(owner_type: 'Board', id: params[:id]).first
          if board = Board.where(id: params[:item]).first
            thread.owner_id = board.id
            thread.save
            return render json: {
              board.id => true
            }
          end
        end
      end
      head 401
    end
  end
end
