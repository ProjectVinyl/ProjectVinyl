class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :set_start_time
  before_filter :configure_permitted_parameters, if: :devise_controller?
  after_filter :store_last_location, if: :not_devise_controller?
  after_filter :sign_out_after, if: :devise_controller?
  
  def not_devise_controller?
    !devise_controller? && controller_name != "ajax" && request.fullpath.index('/ajax/').nil?
  end
  
  def stored_location_for(resource)
    nil
    #request.referrer
  end
  
  def after_sign_in_path_for(resource)
    #puts "user_return_to: "
    #puts  session["user_return_to"]
    session["user_return_to"] || root_path
  end
  
  def after_sign_out_path_for(resource_or_scope)
    puts "user_return_to (out): "
    puts  request.referrer
    request.referrer
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
    session["user_return_to"] = request.fullpath
  end
  
  def sign_out_after
    #puts "Devise! " + controller_name
    #puts action_name
    #puts request.referrer
  end
end
