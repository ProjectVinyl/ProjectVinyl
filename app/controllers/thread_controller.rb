class ThreadController < ApplicationController
  def view
    if @thread = CommentThread.where(id: params[:id]).first
      if @thread.owner_id
        redirect_to action: 'view', controller: @thread.owner_type.downcase, id: @thread.owner_id
        return
      end
      @order = '0'
      @results = @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_admin), (params[:page] || -1).to_i, 10, false)
    end
  end
  
  def post_comment
    if user_signed_in?
      if @thread = CommentThread.where(id: params[:thread]).first
        comment = Comment.create(user_id: current_user.id, comment_thread_id: @thread.id)
        comment.update_comment(params[:comment])
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
          Notification.notify_recievers_without_delete(recievers, @thread.owner,
            current_user.username + " has posted a reply to <b>" + @thread.title + "</b>",
            @thread.location)
        else
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
          comment.save
          render json: {
            message: "success",
            content: render_to_string(partial: '/thread/comment.html.erb', locals: { comment: comment, indirect: false }),
          }
        else
          comment.hidden = true
          comment.save
          render json: {
            message: "success", reload: true
          }
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
