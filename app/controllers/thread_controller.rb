class ThreadController < ApplicationController
  def view
    if !(@thread = CommentThread.where('id = ? AND (owner_type IS NULL OR owner_type = "video")', params[:id]).first)
      return render '/layouts/error', locals: { title: 'Nothing to see here!', description: "Either the thread does not exist or you don't have the neccessary permissions to see it." }
    end
    @order = '0'
    @modificationsAllowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_contributor?)
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), (params[:page] || -1).to_i, 10, false)
  end
  
  def new
    @thread = CommentThread.new
    if params[:user] && @user = User.where(id: params[:user]).first
      return render partial: 'pm/new'
    end
    render partial: 'new'
  end
  
  def create
    if user_signed_in?
      thread = CommentThread.create(user_id: current_user.id, total_comments: 1)
      thread.set_title(params[:thread][:title])
      thread.save
      comment = thread.comments.create(user_id: current_user.id)
      comment.update_comment(params[:thread][:description])
      if current_user.subscribe_on_thread?
        thread.subscribe(current_user)
      end
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
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(listing_selector, @page, 50, false)
    render template: '/view/listing', locals: {type_id: 4, type: 'threads', type_label: 'Thread', items: @results}
  end
  
  def page_threads
    @page = params[:page].to_i
    @results = Pagination.paginate(listing_selector, @page, 50, false)
    render json: {
      content: render_to_string(partial: '/thread/thread_thumb.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def listing_selector
    return CommentThread.includes(:direct_user).where(owner_id: nil, owner_type: nil).order('pinned DESC, locked ASC, created_at DESC')
  end
  
  def post_comment
    if user_signed_in?
      if (@thread = CommentThread.where(id: params[:thread]).first) && !@thread.locked
        comment = @thread.comments.create(user_id: current_user.id, o_comment_thread_id: @thread.id)
        @thread.total_comments = @thread.comments.count
        @thread.save
        comment.update_comment(params[:comment])
        
        if params[:quick]
          @comments = @thread.comments.includes(:direct_user).order(:created_at).reverse_order.limit(50).reverse()
          return render json: {
            content: render_to_string(partial: 'thread/chat_message_set', locals: { thread: @comments })
          }
        end
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
    render status: 401, nothing: true
  end
  
  def edit_comment
    if user_signed_in? && (comment = Comment.where(id: params[:id]).first)
      comment.update_comment(params[:comment])
      render status: 200, nothing: true
      return
    end
    render status: 401, nothing: true
  end
  
  def get_comment
    if comment = Comment.where(id: params[:id]).first
      render partial: '/thread/comment', locals: { comment: comment, indirect: false }
      return
    end
    render status: 404, nothing: true
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
            content: render_to_string(partial: '/thread/comment.html.erb', locals: { comment: comment, indirect: false }),
          }
        else
          comment.hidden = true
          CommentThread.where(id: comment.comment_thread_id).update_all('total_comments = total_comments - 1')
          comment.save
          if current_user.is_contributor?
            render json: {
              message: "success",
              content: render_to_string(partial: '/thread/comment.html.erb', locals: { comment: comment, indirect: false }),
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
    render status: 401, nothing: true
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
      current_user.notification_count = 0
      current_user.save
    else
      redirect_to action: "view", controller: "welcome"
    end
  end
  
  def delete_notification
    if user_signed_in?
      if item = Notification.where(id: params[:id], user_id: current_user.id).first
        item.destroy
        return render status: 200, nothing: true
      end
      return render status: 404, nothing: true
    end
    render status: 402, nothing: true
  end
end
