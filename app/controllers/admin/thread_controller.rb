module Admin
  class ThreadController < ApplicationController
    before_action :check_permission
    
    def pin
      if !(@thread = CommentThread.where(id: params[:id]).first)
        return head 404
      end
      
      render json: {
        added: @thread.pinned = !@thread.pinned
      }
      @thread.save
    end

    def lock
      if !(@thread = CommentThread.where(id: params[:id]).first)
        return head 404
      end
      
      render json: {
        added: @thread.locked = !@thread.locked
      }
      @thread.save
    end
    
    def move
      if !(@thread = CommentThread.where(id: params[:id], owner_type: 'Board').first)
        return head 404
      end
      
      if !(@board = Board.where(id: params[:item]).first)
        return head 404
      end
      
      @thread.owner_id = @board.id
      @thread.save
      render json: {
        @board.id => true
      }
    end
    
    protected
    def check_permission
      if !user_signed_in? || !current_user.is_contributor?
        head 401
      end
    end
  end
end
