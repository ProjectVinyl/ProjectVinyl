class ApplicationController < ActionController::Base
  include Paginateable
  include Errorable
  
  protect_from_forgery with: :exception
  
  before_action :set_start_time
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :store_last_location, if: :content_page?
  after_action :poke_user, if: :user_signed_in?
  
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
end
