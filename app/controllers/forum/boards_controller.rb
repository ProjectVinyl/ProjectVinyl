module Forum
  class BoardsController < ApplicationController
    def show
      if !(@board = Board.find_board(params[:id]))
        
        if params[:format] == 'json'
          return head :not_found
        end
        
        return render_error(
          title: 'Nothing to see here!',
          description: 'That forum does not exist.'
        )
      end
      
      @threads = Pagination.paginate(@board.threads, params[:page].to_i, 50, false)
      @modifications_allowed = user_signed_in? && current_user.is_contributor?
      
      if params[:format] == 'json'
        render_pagination_json 'threads/thumb', @threads
      end
    end
    
    def index
      @crumb = {
        stack: [],
        title: "Forum"
      }
      @boards = Pagination.paginate(Board.sorted, params[:page].to_i, 10, false)
      if params[:format] == 'json'
        render_pagination_json 'thumb', @boards
      end
    end
    
    def new
      @board = Board.new
      render partial: 'new', locals: {url: forum_index_path, method: :post}
    end

    def create
      if !user_signed_in? && !current_user.is_contributor?
        return redirect_to action: :index, controller: :welcome
      end
      board = Board.create(params[:board].permit(:title, :short_name, :description))

      redirect_to action: :show, id: board.short_name
    end
    
    def edit
      if !(@board = Board.where(id: params[:id]).first)
        return head :not_found
      end
      
      render partial: 'new', locals: {url: forum_path(@board), method: :patch}
    end
    
    def update
      if !user_signed_in? || !current_user.is_contributor?
        return head :unauthorized
      end
      
      if !(board = Board.where(id: params[:id]).first)
        return head :not_found
      end
      
      if params[:board]
        board.short_name = params[:board][:short_name]
        board.title = params[:board][:title]
        board.description = params[:board][:description]
        board.save
        
        return redirect_to action: :show, id: board.short_name
      end
      
      if params[:field] == 'title'
        board.title = params[:value]
        board.save
        return render json: { content: board.title }
      end
      
      head :ok
    end
    
    def destroy
      if !user_signed_in? || !current_user.is_contributor?
        flash[:error] = 'Access Denied'
        return redirect_to action: :index, controller: :welcome
      end
      
      if board = Board.where(id: params[:id]).first
        board.destroy
      end
      
      redirect_to action: :index
    end
  end
end
