require_relative 'boot'
require 'rails/all'
require_relative 'csp'

Bundler.require(*Rails.groups)

module Projectvinyl
  class Application < Rails::Application
    
    #Disable asset generation
    config.generators do |g|
      g.assets false
    end

    config.middleware.use Rack::Cors do
      allow do
        origins ['localhost:8080','lvh.me:8080','upload.lvh.me:8080','projectvinyl.net','upload.projectvinyl.net','www.projectvinyl.net']
        resource '*',
          :headers => :any,
          :credentials  => true,
          :methods => [:put, :post, :patch],
          :expose  => ['x-csrf-token', 'access-token', 'expiry', 'token-type', 'uid', 'client']
      end
    end

    # Special headers
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'Content-Security-Policy' => ProjectVinyl::Csp.headers[:default]
    }
    
    # Fucking rails
    config.autoload_paths += %W[#{config.root}/lib]
    config.eager_load_paths += %W[#{config.root}/lib]
    
    #Handle json like a sane person
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
