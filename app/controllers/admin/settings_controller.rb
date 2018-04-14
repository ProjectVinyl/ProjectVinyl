module Admin
  class SettingsController < BaseAdminController
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
        head :unauthorized
      end
    end
  end
end
