module Admin
  module Forum
    module Threads
      class MovesController < BaseThreadsController
        def update
          return head :not_found if !(@thread = CommentThread.where(id: params[:thread_id], owner_type: 'Board').first)
          return head :not_found if !(@board = Board.where(id: params[:item]).first)
          @thread.owner_id = @board.id
          @thread.save
          render json: {
            @board.id => true
          }
        end
      end
    end
  end
end
