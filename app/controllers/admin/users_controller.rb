module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    
    def show
      if !current_user.is_contributor?
        return render_access_denied
      end
      @user = User.find(params[:id])
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { link: @user.link, title: @user.id }
        ],
        title: @user.username
      }
    end
    
    def role
      if !current_user.is_staff?
        return head 401
      end
      
      if params[:user_id].to_i == current_user.id
        return head 401
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
    
    def toggle_badge
      if !current_user.is_contributor?
        return head :unauthorized
      end
      
      if existing = UserBadge.where(user_id: params[:user_id], badge_id: params[:id]).first
        existing.destroy
        return render json: {
          added: false
        }
      end
      
      if !(user = User.where(id: params[:user_id]).first)
        return head :not_found
      end
      
      if !(badge = Badge.where(id: params[:id]).first)
        return head :not_found
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
