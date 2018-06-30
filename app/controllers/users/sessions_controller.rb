class Users::SessionsController < Devise::SessionsController
  def new
    return render partial: 'new' if params[:format] == 'json'
    super
  end
end
