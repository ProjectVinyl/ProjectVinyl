class ApplicationController < ActionController::Base
  include Paginateable
  include Errorable
  include Trackable

  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def default_filter
    helpers.default_filter
  end
  
  def current_filter
    helpers.current_filter
  end

  def cache_videos(elastic_record, key)
    helpers.cache_videos(elastic_record, key)
  end

  def anonymous_user_id
    user_signed_in? ? current_user.id : UserAnon.anon_id(session)
  end
end
