class ApplicationController < ActionController::Base
  include Paginateable
  include Errorable
  include Trackable

  protect_from_forgery with: :exception

  before_action :set_time_zone
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def current_filter
    helpers.current_filter
  end

  def anonymous_user_id
    user_signed_in? ? current_user.id : UserAnon.anon_id(session)
  end

  def set_time_zone
    Time.zone = current_user.time_zone if current_user
  end
end
