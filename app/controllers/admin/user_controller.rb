module Admin
  class UserController < ApplicationController
    before_action :authenticate_user!
    
    def view
      if !current_user.is_contributor?
        return render_access_denied
      end
      @user = User.find(params[:id])
    end
    
    def role
      if !current_user.is_staff?
        return head 401
      end
      
      if params[:id].to_i == current_user.id
        return head 401
      end
      
      user = User.where(id: params[:id]).first
      role = Roleable.role_for(params[:role])
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
    
    def toggle_badge
      if !current_user.is_contributor?
        return head 401
      end
      
      if !(user = User.where(id: params[:id]).first)
        return head 404
      end
      
      if existing = user.user_badges.where(badge_id: params[:badge_id]).first
        existing.destroy
        return render json: {
          added: false
        }
      end
      
      if !(badge = Badge.where(id: params[:badge_id]).first)
        return head 404
      end
      
      user.user_badges.create({
        badge_id: badge.id,
        custom_title: badge.badge_type > 0 && params[:extra] ? params[:extra] : ""
      })
      
      render json: {
        added: true
      }
    end
  end
end
