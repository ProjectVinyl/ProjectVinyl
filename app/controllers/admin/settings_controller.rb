module Admin
  class SettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :check_permissions
    
    def set
      render json: {
        value: ApplicationSettings.set(params[:key], params[:value])
      }
    end
    
    def toggle
      render json: {
        added: ApplicationSettings.toggle(params[:key].to_sym)
      }
    end
    
    private
    def check_permissions
      if !current_user.is_contributor?
        return head :unauthorized
      end
    end
  end
end
