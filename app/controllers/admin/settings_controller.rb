module Admin
  class SettingsController < BaseAdminController
    before_action :check_permissions
    
    def set
      render json: {
        value: ApplicationSettings.set(params[:key], params[:value])
      }
    end
    
    def toggle
      if (params[:key] == 'elastic_read_only')
        return render json: {
          added: ElasticSearch.read_only = !ElasticSearch.read_only?
        }
      end
      render json: {
        added: ApplicationSettings.toggle(params[:key].to_sym)
      }
    end
    
    private
    def check_permissions
      head :unauthorized if !current_user.is_contributor?
    end
  end
end
