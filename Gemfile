source 'http://rubygems.org'

gem 'rails', '5.1.2'
gem 'mysql2', '>= 0.3.18', '< 0.5'

# Use Html sanitizer
gem 'rails-html-sanitizer'

gem 'sdoc', '~> 0.4.0', group: :doc
gem 'jquery-rails'
gem 'uglifier'
gem 'yui-compressor'

gem 'haml'

platforms :ruby do
  gem 'unicorn'
end

# User sign-in/sign-out
gem 'devise'

# For push notifications
gem 'webpush'

# Anon verification
gem 'recaptcha', require: 'recaptcha/rails'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'better_errors', github: 'charliesome/better_errors'
  gem 'binding_of_caller'
  gem 'rubocop', require: false
  gem 'listen'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Searching with elasicsearch
gem 'elasticsearch-rails'
gem 'elasticsearch-model'

gem 'resque'
gem 'foreman'
gem 'eye'

gem 'sprockets-rollup'
