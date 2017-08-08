module Forum
  class BoardController < ApplicationController
    def view
      if !(@board = Board.find_board(params[:id]))
        return render 'layouts/error', locals: {
          title: 'Nothing to see here!',
          description: 'That forum does not exist.'
        }
      end
      @modifications_allowed = user_signed_in? && current_user.is_contributor?
      @threads = Pagination.paginate(@board.threads, params[:page].to_i, 50, false)
    end
    
    def index
      @boards = Pagination.paginate(Board.all, params[:page].to_i, 10, false)
    end

    def page
      render_pagination 'thumb', Pagination.paginate(Board.all, params[:page].to_i, 10, false)
    end
    
    def new
      @board = Board.new
      render partial: 'new'
    end

    def create
      if !user_signed_in? && !current_user.is_contributor?
        return redirect_to action: 'index', controller: 'welcome'
      end
      board = Board.create({
        title: params[:board][:title],
        description: params[:board][:description]
      })
      redirect_to action: "view", controller: "board", id: board.title
    end
    
    def update
      if !user_signed_in? || !current_user.is_contributor?
        return head 401
      end
      
      if !(board = Board.find_board(params[:board][:id]))
        return head 404
      end
      
      board.title = params[:board][:title]
      board.description = params[:board][:description]
      board.save
      
      return head 200
    end
    
    def destroy
      if !user_signed_in? || !current_user.is_contributor?
        flash[:error] = 'Access Denied'
        redirect_to action: 'index', controller: 'welcome'
      end
      
      if board = Board.where(id: params[:id]).first
        board.destroy
      end
      
      redirect_to action: 'index'
    end
  end
end
