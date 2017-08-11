class NotificationController < ApplicationController
  def index
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
  
  def view
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
  
  def destroy
    if user_signed_in?
      if notification = current_user.notifications.where(id: params[:id]).first
        notification.destroy
        current_user.notification_count = current_user.notifications.where(unread: true).count
        current_user.save
        return head :ok
      end
      return head 404
    end
    head 402
  end
end
