module Ajax
  class NotificationController < ApplicationController
    def view
      if !user_signed_in?
        return head 401
      end
      
      if current_user.notification_count != params[:notices].to_i
      || current_user.feed_count         != params[:feeds].to_i
      || current_user.message_count      != params[:mail].to_i
        return render json: {
          notices: current_user.notification_count,
          feeds: current_user.feed_count,
          mail: current_user.message_count
        }
      end
      
      head 204
    end
  end
end
