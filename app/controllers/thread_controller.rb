class ThreadController < ApplicationController
  def post_comment
    if user_signed_in? && Comment.thread_exists?(params[:thread])
      comment = Comment.create(user_id: current_user.id, video_id: params[:thread])
      comment.update_comment(params[:comment])
      @results = Pagination.paginate(Comment.pull_thread(params[:thread]), 0, 10, false)
      render json: {
        content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records }),
        pages: @results.pages,
        page: @results.page,
        focus: comment.get_open_id
      }
      return
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
      render partial: '/thread/comment', locals: { comment: comment }
      return
    end
    render status: 404, nothing: true
  end
  
  def remove_comment
    if user_signed_in?
      if comment = Comment.where(id: params[:id]).first
        if current_user.is_admin || current_user.id == comment.user_id
          comment.destroy
          render json: {
            message: "success"
          }
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Comment.pull_thread(params[:thread_id]), @page, 10, false)
    render json: {
      content: render_to_string(partial: '/thread/comment_set.html.erb', locals: { thread: @results.records }),
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
