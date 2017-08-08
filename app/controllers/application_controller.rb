class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_start_time
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :store_last_location, if: :content_page?

  def content_page?
    !devise_controller? && controller_name != "ajax" && controller_name != "imgs" && action_name != "download" && request.fullpath.index('/ajax/').nil?
  end
  
  def render_pagination(partial, pagination)
    render json: {
      content: render_to_string(partial: partial, collection: pagination.records),
      pages: pagination.pages,
      page: pagination.page
    }
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
end
