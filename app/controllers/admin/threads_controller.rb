module Admin
  class ThreadsController < BaseAdminController
    def pin
      toggle_action do |thread|
        thread.pinned = !thread.pinned
      end
    end

    def lock
      toggle_action do |thread|
        thread.locked = !thread.locked
      end
    end
    
    def move
      if !(@thread = CommentThread.where(id: params[:thread_id], owner_type: 'Board').first)
        return head :not_found
      end
      
      if !(@board = Board.where(id: params[:item]).first)
        return head :not_found
      end
      
      @thread.owner_id = @board.id
      @thread.save
      render json: {
        @board.id => true
      }
    end
    
    def destroy
      if !(@thread = CommentThread.where(id: params[:id], owner_type: 'Board').first)
        return head :not_found
      end
      
      @thread.destroy
      
      redirect_to action: :show, controller: 'forum/boards', id: @thread.owner.short_name
    end
    
    protected
    def toggle_action
      if !(thread = CommentThread.where(id: params[:thread_id]).first)
        return head :not_found
      end
      
      render json: {
        added: yield(thread)
      }
      thread.save
    end
    
    def check_permission
      if !user_signed_in? || !current_user.is_contributor?
        head 401
      end
    end
  end
end
