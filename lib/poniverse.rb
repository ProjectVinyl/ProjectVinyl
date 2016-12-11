require 'omniauth-oauth2'
require 'json'

module OmniAuth
  module Strategies
    class Poniverse < OmniAuth::Strategies::OAuth2
      option :name, :poniverse
      option :client_options, {
        :site => 'https://api.poniverse.net',
        :authorize_url => 'https://poniverse.net/oauth/authorize',
        :token_url => 'https://poniverse.net/oauth/access_token',
        :proxy => ENV['http_proxy'] ? URI(ENV['http_proxy']) : nil
      }
      uid {
        raw_info['user_id']
      }
      
      info do
        {
          :nickname => raw_info['display_name'],
          :name => raw_info['username'],
          :email => raw_info['email']
        }
      end
      
      def raw_info
        @raw_info ||= access_token.get('/v1/users/me').parsed
      end
      
      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end