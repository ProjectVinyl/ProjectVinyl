module Embed
  class EmbedController < ActionController::Base
    include ApplicationHelper
    protect_from_forgery with: :exception
    after_action :allow_embeds
    
    def define_custom_headers
      response.headers['Content-Security-Policy'] = ProjectVinyl::Csp.headers[:embed]
    end
    
    private
    
    def allow_embeds
      response.headers.except! 'X-Frame-Options'
      define_custom_headers
    end
  end
end
