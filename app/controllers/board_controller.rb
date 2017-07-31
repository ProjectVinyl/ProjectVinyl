class BoardController < ApplicationController
  def view
    if !(@board = Board.find_board(params[:id]))
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: 'That forum does not exist.' }
    end
    @modifications_allowed = user_signed_in? && current_user.is_contributor?
    @page = params[:page].to_i
    @threads = Pagination.paginate(@board.threads, @page, 50, false)
  end
  
  def index
    @page = params[:page].to_i
    @boards = Pagination.paginate(Board.all, @page, 10, false)
  end

  def page
    @page = params[:page].to_i
    @boards = Pagination.paginate(Board.all, @page, 10, false)
    render json: {
      content: render_to_string(partial: 'board/thumb.html.erb', collection: @boards.records),
      pages: @boards.pages,
      page: @boards.page
    }
  end
  
  def new
    @board = Board.new
    render partial: 'new'
  end

  def create
    if user_signed_in? && current_user.is_contributor?
      board = Board.create(title: params[:board][:title], description: params[:board][:description])
      return redirect_to action: "view", controller: "board", id: board.title
    end
    redirect_to action: 'index', controller: 'welcome'
  end
  
  def update
    if user_signed_in? && current_user.is_contributor? && board = Board.find_board(params[:board][:id])
      board.title = params[:board][:title]
      board.description = params[:board][:description]
      board.save
      return head 200
    end
    head 401
  end
  
  def destroy
    if user_signed_in? && current_user.is_contributor?
      if board = Board.where(id: params[:id]).first
        board.destroy
        return render json: {
          ref: url_for(action: "list", controller: "board")
        }
      end
    end
    flash[:error] = 'Access Denied'
    redirect_to action: 'index', controller: 'welcome'
  end
end
