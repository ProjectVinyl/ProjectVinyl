class ApplicationController < ActionController::Base
  include Paginateable
  include Errorable
  
  protect_from_forgery with: :exception
  
  before_action :set_start_time
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :poke_user, if: :user_signed_in?
  after_action :allow_cors
  after_action :store_last_location, if: :content_page?
  
  def content_page?
    !devise_controller? && controller_name != "imgs" && action_name != "download" && (/\/(api|ajax|.json)\// =~ request.fullpath).nil?
  end
  
  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end
  
  def set_start_time
    @start_time = Time.now
  end
  
  def store_last_location
    return unless request.get?
    store_location_for('user', request.fullpath)
  end
  
  def anonymous_user_id
    user_signed_in? ? current_user.id : UserAnon.anon_id(session)
  end
  
  def poke_user
    current_user.poke
  end

  private

  def allow_cors

    gateway = Rails.application.config.gateway
    gateway_no_port = gateway.split(':')[0]

    host = gateway.remove('upload.')
    host_no_port = host.split(':')[0]

    if (request.host == host_no_port || request.host == gateway_no_port)
      response.headers['Access-Control-Allow-Origin'] = request.host == host_no_port ? gateway : host
      response.headers['Vary'] = 'Origin'
    end
  end
end
