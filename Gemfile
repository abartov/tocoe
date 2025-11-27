source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
gem 'mysql2'
gem 'devise'
gem 'omniauth-google-oauth2'
gem "omniauth-rails_csrf_protection"
gem 'haml-rails'
gem 'puma'
gem 'logger'
# Use SCSS for stylesheets
gem 'sass-rails'
gem 'bootstrap-sass'
gem 'rest-client'
gem 'httparty' # for consuming JSON APIs
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'cucumber'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  # gem 'debug' # uncomment to debug tests
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'debug'
  gem 'web-console'
  gem 'listen'
end

group :test do
  gem 'faker'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webmock'
end