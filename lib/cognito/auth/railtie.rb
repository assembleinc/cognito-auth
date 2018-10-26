require 'cognito/auth/middleware'
module Cognito
  module Auth
    class Railtie < Rails::Railtie
      initializer 'railtie.configure_rails_initialization' do |app|
        app.middleware.insert_after ActionDispatch::Session::CookieStore, Cognito::Auth::Middleware
      end
    end
  end
end
