class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_action :check_captcha, only: [:create]
  prepend_before_action :load_tab, only: [:edit]

  private
  def load_tab
    @current_tab = (params[:tab] || "profile").to_sym
    @tab_selection_hash = Hash.new({})
    @tab_selection_hash[@current_tab] = {class: "selected"}
  end

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
