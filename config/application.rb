require_relative 'boot'
require 'rails/all'
require_relative 'csp'

Bundler.require(*Rails.groups)

module Projectvinyl
  class Application < Rails::Application
    
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    
    config.generators do |g|
      g.assets false
    end
    
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'Content-Security-Policy' => ProjectVinyl::Csp.headers[:default]
    }
    
    # Fucking rails
    config.autoload_paths += %W[#{config.root}/lib]
    config.eager_load_paths += %W[#{config.root}/lib]
    config.active_support.escape_html_entities_in_json = false
    config.active_record.belongs_to_required_by_default = false
    config.active_job.queue_adapter = :resque
    
    # Git
    config.after_initialize do
      ::Git_branch = `git rev-parse --abbrev-ref HEAD`.chomp
      ::Git_version = `git rev-parse --short HEAD`.chomp
    end
  end
end
