module Errorable
  extend ActiveSupport::Concern

  NotAuthorized = Class.new(StandardError)

  included do
    rescue_from NotAuthorized do |exception|
      render file: 'public/401', status: :unauthorized, layout: false
    end
  end

  def render_error(pars)
    render 'layouts/error', locals: pars
  end

  def render_error_file(code, ajax)
    return head code if ajax
    render file: "/public/#{code}", status: code, layout: false
  end

  def render_access_denied
    render_error(
      title: "Access Denied",
      description: "You can't do that right now."
    )
  end

  def error(title, message)
    respond_to do |format|
      format.json { render plain: "#{title}:#{message}", status: :unauthorized }
      format.any { render_error title: title, description: message }
    end
  end

  def check_error(async, condition, title, message)
    error(async, title, message) if condition
    return condition
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def forbidden
    raise NotAuthorized
  end
end
