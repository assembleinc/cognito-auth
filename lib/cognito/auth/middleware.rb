module Cognito
  module Auth
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        Cognito::Auth.configure do |config|
          config.session = request.cookie_jar
        end

        @app.call(env)
      end
    end
  end
end
