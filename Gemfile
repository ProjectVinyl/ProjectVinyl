source 'http://rubygems.org'

gem 'rails', '5.1.6.2'
gem 'pg'
gem 'rails-html-sanitizer'
gem 'rack-cors', :require => 'rack/cors'

gem 'sdoc', '~> 0.4.0', group: :doc
gem 'jquery-rails'
gem 'uglifier'
gem 'yui-compressor'
gem 'haml'

platforms :ruby do
  gem 'unicorn'
end

gem 'webpush' # For push notifications
gem 'devise' # User sign-in/sign-out
gem 'recaptcha', require: 'recaptcha/rails' # Anon verification
gem 'ahoy_matey' # Analytics!

group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'better_errors', github: 'charliesome/better_errors'
  gem 'binding_of_caller'
  gem 'rubocop', require: false
  gem 'listen'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'elasticsearch-model' # Searching with elasicsearch

gem 'puma'
gem 'resque'
gem 'foreman'
gem 'eye'

gem 'sprockets', '~>3.0' # Sprockets 4 is broken
gem 'sprockets-rollup'
