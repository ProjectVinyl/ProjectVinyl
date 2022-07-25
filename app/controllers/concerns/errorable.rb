module Errorable
  extend ActiveSupport::Concern

  def render_access_denied
    render_error(
      title: "Access Denied",
      description: "You can't do that right now.",
      status: :unauthorized
    )
  end

  def render_error(pars, status: :ok)
    render 'layouts/error', locals: pars, status: status
  end

  def render_status_page(status)
    respond_to do |format|
      format.json { head status }
      format.html { render file: "/public/error_#{status_code_of(status)}", status: status, layout: false }
      format.xml { render file: "/public/error_#{status_code_of(status)}", status: status, layout: false }
      format.any { render plain: status, status: status }
    end
  end

  def error(title, message, status = :unauthorized)
    respond_to do |format|
      format.json { render json: { error: "#{title}:#{message}", success: false }, status: status }
      format.html { render_error title: title, description: message, status: status }
      format.xml { render_error title: title, description: message, status: status }
      format.any { render plain: "#{title}:#{message}", status: status }
    end
  end

  private
  def status_code_of(symbol)
    return symbol if 1.is_a?(symbol.class)
    Rack::Utils::SYMBOL_TO_STATUS_CODE[symbol.to_sym]
  end
end
