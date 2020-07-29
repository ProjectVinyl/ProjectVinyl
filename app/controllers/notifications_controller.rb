class NotificationsController < ApplicationController
  def index
    return redirect_to action: :index, controller: :welcome if !user_signed_in?

    @all = current_user.notifications.order(:created_at).reverse_order.preload_comment_threads
    @notifications = current_user.notification_count
    current_user.notifications.where('created_at < ?', 1.week.ago).delete_all
    current_user.notification_count = current_user.notifications.where(unread: true).count
    current_user.save
  end

  def show
    return redirect_to action: :index, controller: :welcome if !user_signed_in?

    if !(notification = current_user.notifications.where(id: params[:id]).first)
      return redirect_to action: :index, controller: :welcome
    end

    if notification.unread
      current_user.notifications.where(id: params[:id]).update_all(unread: false)
      current_user.notification_count = current_user.notifications.where(unread: true).count
      current_user.save
    end

    redirect_to notification.source
  end

  def destroy
    return head 402 if !user_signed_in?
    return head :not_found if !(notification = current_user.notifications.where(id: params[:id]).first)

    notification.destroy
    current_user.notification_count = current_user.notifications.where(unread: true).count
    current_user.save

    render json: {}
  end
end
