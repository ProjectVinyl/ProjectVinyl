module Embed
  class TwitterController < Embed::EmbedController
    def define_custom_headers
      response.headers['Content-Security-Policy'] = ProjectVinyl::Csp.headers[:twitter]
    end
  end
end
