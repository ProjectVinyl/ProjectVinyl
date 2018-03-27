module Admin
  class RolesController < ApplicationController
    before_action :authenticate_user!
    
    def update
      if !current_user.is_staff? || params[:user_id].to_i == current_user.id
        return head :unauthorized
      end
      
      user = User.where(id: params[:user_id]).first
      role = Roleable.role_for(params[:id])
      if role <= current_user.role
        user.role = role
        user.save
      end
      
      return render json: {
        admin: user.admin?,
        contributor: user.contributor?,
        staff: user.staff?,
        normal: user.role == 0,
        banned: user.banned?
      }
    end
  end
end