module Users
  class BaseUsersController < ApplicationController
    protected
    def check_details_then
      if !(@user = User.where(id: params[:user_id] || params[:id]).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'If there was someone here they\'re probably gone now. ... sorry.'
        )
      end
      
      yield(@user, user_signed_in? && (current_user.id == @user.id || current_user.is_staff?))
    end
    
    def check_then
      return render_access_denied if !user_signed_in?

      id = (params[:user_id] || params[:id]).to_i
      
      return yield(current_user) if id == current_user.id
      return render_access_denied if !current_user.is_staff?
      return head :not_found if !(user = User.where(id: id).first)
      yield(user)
    end
  end
end
