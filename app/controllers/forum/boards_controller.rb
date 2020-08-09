module Forum
  class BoardsController < ApplicationController
    def show
      return render_error_file 404, params[:format] == 'json' if !(@board = Board.find_board(params[:id]))

      @threads = Pagination.paginate(@board.threads, params[:page].to_i, 50, false)
      @modifications_allowed = user_signed_in? && current_user.is_contributor?

      render_paginated @threads, partial: 'forum/threads/thumb', as: :json if params[:format] == 'json'
    end

    def index
      @crumb = {
        stack: [],
        title: "Forum"
      }
      @boards = Pagination.paginate(Board.sorted, params[:page].to_i, 10, false)
      render_paginated @boards, partial: 'thumb', as: :json  if params[:format] == 'json'
    end

    def new
      @board = Board.new
      render partial: 'new', locals: {url: forum_index_path, method: :post}
    end

    def create
      return redirect_to action: :index, controller: :welcome if !user_signed_in? && !current_user.is_contributor?
      board = Board.create(params[:board].permit(:title, :short_name, :description))

      redirect_to action: :show, id: board.short_name
    end

    def edit
      return head :not_found if !(@board = Board.where(id: params[:id]).first)
      render partial: 'new', locals: {url: forum_path(@board), method: :patch}
    end

    def update
      return head :unauthorized if !user_signed_in? || !current_user.is_contributor?
      return head :not_found if !(board = Board.where(id: params[:id]).first)

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

      board.destroy if board = Board.where(id: params[:id]).first

      redirect_to action: :index
    end
  end
end
