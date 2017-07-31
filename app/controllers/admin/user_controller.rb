module Admin
  class UserController < ApplicationController
    before_action :authenticate_user!
    
    def view
      if !user_signed_in? || !current_user.is_contributor?
        return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      end
      @user = User.find(params[:id])
    end
    
    def role
      if user_signed_in? && current_user.is_staff?
        if params[:id].to_i != current_user.id && user = User.where(id: params[:id]).first
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
      end
      head 401
    end
    
    def toggle_badge
      if user_signed_in? && current_user.is_contributor?
        if user = User.where(id: params[:id]).first
          if existing = user.user_badges.where(badge_id: params[:badge_id]).first
            existing.destroy
            render json: { added: false }
          elsif badge = Badge.where(id: params[:badge_id]).first
            if badge.badge_type > 0 && params[:extra]
              user.user_badges.create(badge_id: badge.id, custom_title: params[:extra])
            else
              user.user_badges.create(badge_id: badge.id)
            end
            render json: { added: true }
          end
        end
        return
      end
      head 401
    end
    
  end
end
