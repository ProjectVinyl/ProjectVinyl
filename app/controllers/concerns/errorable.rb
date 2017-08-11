module Errorable
  def render_error(pars)
    render 'layouts/error', locals: pars
  end
  
  def render_access_denied
    render_error(
      title: "Access Denied",
      description: "You can't do that right now."
    )
  end
  
  def error(async, title, message)
    if async
      return render plain: title + ":" + message, status: 401
    end
    render_error title: title, description: message
  end
  
  def check_error(async, condition, title, message)
    if condition
      error(async, title, message)
    end
    return condition
  end
end
