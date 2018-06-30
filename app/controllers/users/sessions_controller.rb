class Users::SessionsController < Devise::SessionsController
  def new
    if params[:format] == 'json'
      self.resource = resource_class.new(sign_in_params)
      return render partial: 'devise/sessions/new', formats: [:html]
    end
    super
  end
end
