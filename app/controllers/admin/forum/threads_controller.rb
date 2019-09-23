module Admin
  module Forum
    class ThreadsController < Threads::BaseThreadsController
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
    end
  end
end
