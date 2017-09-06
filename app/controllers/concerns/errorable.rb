module Errorable
  def render_error(pars)
    render 'layouts/error', locals: pars
  end
  
  def render_error_file(code, ajax)
    if ajax
      return head code
    end
    
    render file: "/public/#{code}", status: code, layout: false
  end
  
  def render_access_denied
    render_error(
      title: "Access Denied",
      description: "You can't do that right now."
    )
  end
  
  def error(title, message)
    if params[:async]
      return render plain: "#{title}:#{message}", status: 401
    end
    render_error title: title, description: message
  end
  
  def check_error(async, condition, title, message)
    if condition
      error(async, title, message)
    end
    return condition
  end
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def forbidden
    render file: 'public/401', status: 401, layout: false
  end
end
