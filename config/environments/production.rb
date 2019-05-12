Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  config.assets.js_compressor = Uglifier.new(harmony: true)
  config.assets.css_compressor = :yui

  config.assets.compile = false
  config.assets.digest = true

  config.log_level = :debug

  # Actually log things
  RAILS_DEFAULT_LOGGER = Logger.new('log/production.log')
  config.logger = RAILS_DEFAULT_LOGGER
  
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = { host: 'projectvinyl.net' }

  config.i18n.fallbacks = [I18n.default_locale]

  config.active_support.deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new

  config.active_record.dump_schema_after_migration = false
end
