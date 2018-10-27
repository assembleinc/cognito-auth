require 'cognito/auth/helpers'
require 'cognito/auth/configuration'
require 'cognito/auth/version'
require 'cognito/auth/current_user'
require 'cognito/auth/middleware'
require 'cognito/auth/client'
require 'cognito/auth/type'
require 'cognito/auth/railtie' if defined?(Rails)
require 'aws-sdk-cognitoidentityprovider'
require 'cognito/auth/engine' if defined?(Rails)
require 'cognito/auth/concerns/session_controller'
require 'cognito/auth/concerns/password_controller'
require 'cognito/auth/concerns/user_controller'
require 'cognito/auth/concerns/profile_controller'
require 'cognito/auth/errors'
require 'cognito/auth/concerns/group'
require 'cognito/auth/concerns/user'

module Cognito
  module Auth
    extend Cognito::Auth::Helpers
    extend Cognito::Auth::CurrentUser
    extend Cognito::Auth::Client

    class << self
      attr_writer :configuration, :client, :current_user, :errors
      attr_accessor :logged_in
      def client
        @client ||= Aws::CognitoIdentityProvider::Client.new(
          region: configuration.user_pool_region
        )
      end

      def errors
        @errors ||= ActiveModel::Errors.new(Cognito::Auth)
      end

      def configuration
        @configuration ||= Cognito::Auth::Configuration.new
      end

      def configure
        yield(configuration) if block_given?
      end

      def session
        configuration.session
      end

      def session_destroy
        configuration.session_destroy
      end
    end
  end
end
