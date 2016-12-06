require File.expand_path('../boot', __FILE__)
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Projectvinyl
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    # Do not compile controller assets. We're using precompiled stuff. :T
    config.assets.enabled = false
    config.generators do |g|
      g.assets false
    end
    
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'Content-Security-Policy' => "default-src 'self'; form-action 'self' https://syndication.twitter.com/; frame-ancestors *; child-src 'self' https://www.youtube.com; media-src 'self' blob:; img-src * data:; script-src 'self' 'unsafe-inline' https://code.jquery.com/ http://platform.twitter.com/ http://196.25.211.41/ https://cdn.syndication.twimg.com/; style-src 'self' 'unsafe-inline' http://platform.twitter.com/ https://ton.twimg.com;"
    }
    
    # F***n' rails
    config.autoload_paths += %W(#{config.root}/lib)
    
    config.active_support.escape_html_entities_in_json = false
  end
end
