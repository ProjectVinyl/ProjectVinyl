module Users
  class BaseUsersController < ApplicationController
    protected
    def check_details_then
      if !(@user = User.where(id: params[:id] || params[:user_id]).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'If there was someone here they\'re probably gone now. ... sorry.'
        )
      end
      
      yield(@user, user_signed_in? && (current_user.id == @user.id || current_user.is_staff?))
    end
    
    def check_then
      if !user_signed_in?
        return render_access_denied
      end
      
      id = (params[:id] || params[:user_id]).to_i
      
      if id == current_user.id
        return yield(current_user)
      end
      
      if !current_user.is_staff?
        return render_access_denied
      end
      
      if !(user = User.where(id: id).first)
        return head :not_found
      end
      
      yield(user)
    end
  end
end
