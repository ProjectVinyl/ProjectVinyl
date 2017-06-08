source 'http://rubygems.org'

gem 'rails', '4.2.8'
gem 'mysql2'

# Use Html sanitizer
gem 'rails-html-sanitizer'

gem 'sdoc', '~> 0.4.0', group: :doc

platforms :ruby do
  gem 'unicorn'
end

# User sign-in/sign-out
gem 'devise'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  gem 'rubocop', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Searching with elasicsearch
gem 'elasticsearch-rails'
gem 'elasticsearch-model'
