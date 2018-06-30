class NotificationsController < ApplicationController
  def index
    if !user_signed_in?
      return redirect_to action: :index, controller: :welcome
    end
    
    @all = current_user.notifications.order(:created_at).reverse_order.preload_comment_threads
    @notifications = current_user.notification_count
    current_user.notifications.where('created_at < ?', 1.week.ago).delete_all
    current_user.notification_count = current_user.notifications.where(unread: true).count
    current_user.save
  end
  
  def view
    if !user_signed_in?
      return redirect_to action: :index, controller: :welcome
    end
    
    if !(notification = current_user.notifications.where(id: params[:n]).first)
      return redirect_to action: :index, controller: :welcome
    end
    
    if notification.unread
      current_user.notifications.where(id: params[:n]).update_all(unread: false)
      current_user.notification_count = current_user.notifications.where(unread: true).count
    end
    
    redirect_to notification.source
  end
  
  def destroy
    if !user_signed_in?
      return head 402
    end
    
    if !(notification = current_user.notifications.where(id: params[:id]).first)
      return head :not_found
    end
    
    notification.destroy
    current_user.notification_count = current_user.notifications.where(unread: true).count
    current_user.save
    
    render json: {}
  end
end
