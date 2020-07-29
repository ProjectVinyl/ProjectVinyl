module Admin
  module Users
    class RolesController < BaseAdminController
      def update
        return head :unauthorized if !current_user.is_staff? || params[:user_id].to_i == current_user.id

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
end