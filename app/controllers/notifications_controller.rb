class NotificationsController < ApplicationController
  def index
    return redirect_to action: :index, controller: :welcome if !user_signed_in?

    @all = current_user.notifications.includes(:owner).order(:created_at).reverse_order
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
      notification.unread = false
      notification.save
    end

    redirect_to notification.owner.link
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
