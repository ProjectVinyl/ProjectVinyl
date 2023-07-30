Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true

  config.gateway = 'upload.lvh.me:8080'

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.logger = Logger.new('log/mailer.log')
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = { host: 'localhost' }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load

  config.sass.preferred_syntax = :scss
  config.sass.line_comments = false
  config.sass.cache = false

  config.assets.debug = false
  config.assets.compress = true
  config.assets.quiet = true

  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  Elasticsearch::Model.client = Elasticsearch::Client.new(host: 'elasticsearch', port: 9200)
  Resque.redis = Redis.new(host: 'redis', port: 6379)
end
