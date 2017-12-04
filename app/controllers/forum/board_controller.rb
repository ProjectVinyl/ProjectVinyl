module Forum
  class BoardController < ApplicationController
    def view
      if !(@board = Board.find_board(params[:id]))
        return render_error(
          title: 'Nothing to see here!',
          description: 'That forum does not exist.'
        )
      end
      
      @threads = Pagination.paginate(@board.threads, params[:page].to_i, 50, false)
      @modifications_allowed = user_signed_in? && current_user.is_contributor?
    end
    
    def threads
      if !(board = Board.where(id: params[:board_id]).first)
        return head 404
      end
      render_pagination 'thread/thumb', board.threads, params[:page].to_i, 50, false
    end
    
    def index
      @boards = Pagination.paginate(Board.all, params[:page].to_i, 10, false)
      if params[:format] == 'json'
        render_pagination_json 'thumb', @boards
      end
    end
    
    def new
      @board = Board.new
      render partial: 'new'
    end

    def create
      if !user_signed_in? && !current_user.is_contributor?
        return redirect_to action: 'index', controller: 'welcome'
      end
      board = Board.create(
        title: params[:board][:title],
        description: params[:board][:description]
      )
      redirect_to action: "view", controller: "board", id: board.title
    end
    
    def update
      if !user_signed_in? || !current_user.is_contributor?
        return head 401
      end
      
      if !(board = Board.find_board(params[:board][:id]))
        return head :not_found
      end
      
      board.title = params[:board][:title]
      board.description = params[:board][:description]
      board.save
      
      head :ok
    end
    
    def destroy
      if !user_signed_in? || !current_user.is_contributor?
        flash[:error] = 'Access Denied'
        return redirect_to action: 'index', controller: 'welcome'
      end
      
      if board = Board.where(id: params[:id]).first
        board.destroy
      end
      
      redirect_to action: 'index'
    end
  end
end
