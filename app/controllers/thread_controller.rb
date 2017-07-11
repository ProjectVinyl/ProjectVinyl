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

  def move
    if user_signed_in? && current_user.is_contributor? && thread = CommentThread.where(owner_type: 'Board', id: params[:id]).first
      if board = Board.where(id: params[:item]).first
        thread.owner_id = board.id
        thread.save
        return render json: {
          board.id => true
        }
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

  def page_search
    search
    render json: {
      content: render_to_string(partial: '/thread/comment_set', locals: { thread: @results.records, indirect: true }),
      pages: @results.pages,
      page: @results.page
    }
  end

  def post_comment
    if user_signed_in?
      if (@thread = CommentThread.where(id: params[:thread]).first) && !@thread.locked
        comment = @thread.comments.create(user_id: current_user.id, o_comment_thread_id: @thread.id)
        @thread.total_comments = @thread.comments.count
        @thread.save
        comment.update_comment(params[:comment])

        @thread.owner.compute_hotness.save if @thread.owner_type == 'Video'

        @results = Pagination.paginate(@thread.get_comments(current_user.is_contributor?), params[:order] == '1' ? 0 : -1, 10, params[:order] == '1')
        render json: {
          content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records, indirect: false }),
          pages: @results.pages,
          page: @results.page,
          focus: comment.get_open_id
        }
        return @thread.bump(current_user, params, comment)
      end
    end
    head 401
  end

  def edit_comment
    if user_signed_in? && (comment = Comment.where(id: params[:id]).first)
      comment.update_comment(params[:comment])
      head :ok
      return
    end
    head 401
  end

  def get_comment
    if comment = Comment.where(id: params[:id]).first
      render partial: '/thread/comment', locals: { comment: comment, indirect: false }
      return
    end
    head 404
  end

  def remove_comment
    if user_signed_in? && comment = Comment.where(id: params[:id]).first
      if current_user.is_contributor? || current_user.id == comment.user_id
        if comment.hidden && current_user.is_contributor?
          comment.hidden = false
          CommentThread.where(id: comment.comment_thread_id).update_all('total_comments = total_comments + 1')
          comment.save
          render json: {
            message: "success",
            content: render_to_string(partial: '/thread/comment.html.erb', locals: { comment: comment, indirect: !params[:indirect].nil? })
          }
        else
          comment.hidden = true
          CommentThread.where(id: comment.comment_thread_id).update_all('total_comments = total_comments - 1')
          comment.save
          if current_user.is_contributor?
            render json: {
              message: "success",
              content: render_to_string(partial: '/thread/comment.html.erb', locals: { comment: comment, indirect: !params[:indirect].nil? })
            }
          else
            render json: {
              message: "success", reload: true
            }
          end
        end
        return
      end
    end
    head 401
  end

  def page
    @thread = CommentThread.where(id: params[:thread_id]).first
    if params[:comment] && (@comment = Comment.where(comment_thread_id: @thread.id, id: Comment.decode_open_id(params[:comment])).first)
      @page = @comment.page(:id, 10, params[:order] == '1')
    else
      @page = params[:page].to_i
    end
    @results = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), @page, 10, params[:order] == '1')
    render json: {
      content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records, indirect: false }),
      pages: @results.pages,
      page: @results.page
    }
  end

  def notifications
    if user_signed_in?
      @all = current_user.notifications.order(:created_at).reverse_order.preload_comment_threads
      @notifications = current_user.notification_count
      current_user.notifications.where('created_at < ?', 1.week.ago).delete_all
      current_user.notification_count = current_user.notifications.where(unread: true).count
      current_user.save
    else
      redirect_to action: "index", controller: "welcome"
    end
  end

  def mark_read
    if user_signed_in?
      if notification = current_user.notifications.where(id: params[:n]).first
        if notification.unread
          current_user.notifications.where(id: params[:n]).update_all(unread: false)
          current_user.notification_count = current_user.notifications.where(unread: true).count
        end
        return redirect_to notification.source
      end
    end
    redirect_to action: "index", controller: "welcome"
  end

  def delete_notification
    if user_signed_in?
      if item = Notification.where(id: params[:id], user_id: current_user.id).first
        item.destroy
        current_user.notification_count = current_user.notifications.where(unread: true).count
        current_user.save
        return head :ok
      end
      return head 404
    end
    head 402
  end
end
