Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  config.sass.preferred_syntax = :scss
  config.assets.js_compressor = Uglifier.new(harmony: true)

  config.assets.compile = false
  config.assets.digest = true

  config.gateway = 'upload.projectvinyl.net'
  config.log_level = :debug

  # Actually log things
  RAILS_DEFAULT_LOGGER = Logger.new('log/production.log')
  config.logger = RAILS_DEFAULT_LOGGER

  config.action_mailer.logger = Logger.new('log/mailer.log')
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: 'projectvinyl.net',
    user_name: Rails.application.secrets.gmail_public_key,
    password: Rails.application.secrets.gmail_private_key,
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = { host: 'projectvinyl.net' }

  config.i18n.fallbacks = [I18n.default_locale]

  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new

  config.active_record.dump_schema_after_migration = false
end
