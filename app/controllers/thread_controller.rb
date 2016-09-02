class ThreadController < ApplicationController
  def view
    if @thread = CommentThread.where(id: params[:id].split('-')[0]).first
      @order = '0'
      @modificationsAllowed = user_signed_in? && (current_user.id == @thread.user_id || current_user.is_admin)
      @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_admin), (params[:page] || -1).to_i, 10, false)
    end
  end
  
  def new
    @thread = CommentThread.new
    render partial: 'new'
  end
  
  def create
    if user_signed_in?
      thread = params[:thread]
      thread = CommentThread.create(
        user_id: current_user.id, total_comments: 1
      )
      thread.set_title(params[:thread][:title])
      thread.save
      comment = Comment.create(user_id: current_user.id, comment_thread_id: thread.id)
      comment.update_comment(params[:thread][:description])
      redirect_to action: 'view', id: thread.id
      return
    end
    redirect_to action: "index", controller: "welcome"
  end
  
  def update
    if user_signed_in? && thread = CommentThread.where(id: params[:id]).first
      if thread.user_id == current_user.id || current_user.is_admin
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
    return CommentThread.includes(:direct_user).where(owner_id: nil).order('pinned DESC, locked ASC, created_at DESC')
  end
  
  def post_comment
    if user_signed_in?
      if (@thread = CommentThread.where(id: params[:thread]).first) && !@thread.locked
        comment = Comment.create(user_id: current_user.id, comment_thread_id: @thread.id)
        comment.update_comment(params[:comment])
        CommentThread.where(id: @thread.id).update_all('total_comments = total_comments + 1')
        @results = Pagination.paginate(@thread.get_comments(current_user.is_admin), params[:order] == '1' ? 0 : -1, 10, params[:order] == '1')
        render json: {
          content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records, indirect: false }),
          pages: @results.pages,
          page: @results.page,
          focus: comment.get_open_id
        }
        recievers = []
        if @thread.user_id
          recievers << @thread.user_id
        end
        if @thread.owner_type == 'Report'
          if state = params[:report_state]
            @report = @thread.owner
            if state == 'open'
              if !@report.resolved.nil?
                @report.resolved = nil
                Notification.notify_admins(@thread.owner, "Report <b>" + @thread.title + "</b> has been reopened", @thread.location)
              end
            elsif state == 'close'
              if @report.resolved != false
                @report.resolved = false
                Notification.notify_admins(@thread.owner, "Report <b>" + @thread.title + "</b> has been closed", @thread.location)
              end
            elsif state == 'resolve'
              if !@report.resolved
                @report.resolved = true
                Notification.notify_admins(@thread.owner, "Report <b>" + @thread.title + "</b> has been marked as resolved", @thread.location)
              end
            end
            @report.save
          end
          recievers = recievers | @thread.comments.pluck(:user_id)
          recievers = recievers.uniq - [current_user.id]
          Notification.notify_recievers_without_delete(recievers, @thread.owner,
            current_user.username + " has posted a reply to <b>" + @thread.title + "</b>",
            @thread.location)
        else
          recievers = recievers.uniq - [current_user.id]
          Notification.notify_recievers_without_delete(recievers, @thread,
            current_user.username + " has posted a reply to <b>" + @thread.title + "</b>",
            @thread.location)
        end
        return
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
      if current_user.is_admin || current_user.id == comment.user_id
        if comment.hidden && current_user.is_admin
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
          if current_user.is_admin
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
    @page = params[:page].to_i
    @results = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_admin), @page, 10, params[:order] == '1')
    render json: {
      content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records, indirect: false }),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def notifications
    if user_signed_in?
      @all = current_user.notifications.order(:created_at).reverse_order
      @notifications = current_user.notification_count
      @today = @all.where('created_at > ?', Time.zone.now.beginning_of_day)
      @yesterday = @all.where('created_at > ? AND created_at < ?', Time.zone.yesterday.beginning_of_day, Time.zone.yesterday.end_of_day)
      @week = @all.where('created_at > ? AND created_at < ?', 1.week.ago, Time.zone.now.yesterday.beginning_of_day)
      current_user.notifications.where('created_at < ?', 1.week.ago).delete_all
      current_user.notification_count = 0
      current_user.save
    else
      redirect_to action: "view", controller: "welcome"
    end
  end
end
