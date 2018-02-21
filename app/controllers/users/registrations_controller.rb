class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create]
  
  private
  def check_captcha
    unless verify_recaptcha
      set_start_time
      self.resource = resource_class.new sign_up_params
      resource.validate
      respond_with_navigational(resource) { render :new }
    end
  end
  
  def set_start_time
    @start_time = Time.now
  end
end
