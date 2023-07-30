module Embed
  class MastodonsController < Embed::EmbedController
    def define_custom_headers
      response.headers['Content-Security-Policy'] = ProjectVinyl::Csp.headers[:mastodon]
    end
  end
end
