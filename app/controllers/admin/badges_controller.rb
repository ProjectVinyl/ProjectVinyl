module Admin
  class BadgesController < ApplicationController
    before_action :authenticate_user!
    
    def index
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' }
        ],
        title: "Badges"
      }
      @page = params[:page].to_i
      @badges = Badge.all
    end
    
    def new
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      @badge = Badge.new
      render partial: 'new'
    end
    
    def update
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
