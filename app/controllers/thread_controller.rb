class ThreadController < ApplicationController
  def view
    if !(@thread = CommentThread.where('id = ? AND (owner_type = "Board" OR owner_type = "Video")', params[:id]).first)
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: "Either the thread does not exist or you don't have the neccessary permissions to see it." }
    end
    @order = '0'
    @modifications_allowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_contributor?)
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), (params[:page] || -1).to_i, 10, false)
  end

  def new
    @thread = CommentThread.new
    if params[:user] && @user = User.where(id: params[:user]).first
      return render partial: 'pm/new'
    end
    @thread.owner_id = (params[:board] || 0).to_i
    render partial: 'new'
  end

  def create
    if user_signed_in?
      thread = CommentThread.create(user_id: current_user.id, total_comments: 1, owner_type: 'Board', owner_id: params[:thread][:owner_id])
      thread.set_title(params[:thread][:title])
      thread.save
      comment = thread.comments.create(user_id: current_user.id)
      comment.update_comment(params[:thread][:description])
      thread.subscribe(current_user) if current_user.subscribe_on_thread?
      redirect_to action: 'view', id: thread.id
      return
    end
    redirect_to action: "index", controller: "welcome"
  end

  def update
    if user_signed_in? && thread = CommentThread.where(id: params[:id]).first
      if thread.user_id == current_user.id || current_user.is_contributor?
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'title'
          thread.set_title(value)
          thread.save
        end
        head :ok
      end
    end
    head 401
  end
  
  def search
    @page = params[:page].to_i
    @title_query = params[:title_query]
    @poster_query = params[:poster_query]
    @text_query = params[:text_query]
    @ascending = params[:order] == '1'
    @category = (params[:category] || 0).to_i
    @results = []
    @q = Comment.searchable.where('`comment_threads`.owner_type = "Board"').order(:updated_at, :created_at)
    if @title_query
      @q = @q.where('`comment_threads`.title LIKE ?', '%' + @title_query + '%')
    end
    if @poster_query
      @q = @q.joins(:direct_user).where('`users`.username LIKE ?', '%' + @poster_query + '%')
    end
    @q = @q.where('bbc_content LIKE ?', '%' + @text_query + '%') if @text_query
    @q = @q.where('`comment_threads`.owner_id = ?', @category) if @category > 0
    if @title_query || @poster_query || @text_query || (@category > 0)
      @results = @q
    end
    @results = Pagination.paginate(@results, @page, 20, !@ascending)
  end
  
  def page
    if !(@board = Board.where(id: params[:id]).first)
      return head 404
    end
    @page = params[:page].to_i
    @results = Pagination.paginate(@board.threads, @page, 50, false)
    render json: {
      content: render_to_string(partial: '/thread/thread_thumb.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def page_search
    search
    render json: {
      content: render_to_string(partial: '/thread/comment_set', locals: { thread: @results.records, indirect: true }),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def subscribe
    if user_signed_in?
      if thread = CommentThread.where(id: params[:id]).first
        return render json: { added: thread.toggle_subscribe(current_user) }
      end
    end
    head 401
  end
end
