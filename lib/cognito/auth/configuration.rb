module Cognito
  module Auth
    class Configuration
      attr_accessor :user_pool_id, :client_id, :user_pool_region
      attr_accessor :app_group, :token_refresh_rate
      attr_accessor :session, :session_destroy, :auto_verify_email
      attr_accessor :auto_verify_phonenumber, :default_log_in
      attr_accessor :mail_from, :mail_subject

      def initialize
        @token_refresh_rate = 3600
        @auto_verify_email = true
        @auto_verify_phonenumber = false
        @session = {}
        @default_log_in = 'USER_PASSWORD_AUTH'
        @mail_from = 'no-reply@cognitoauth.com'
        @mail_subject = 'You have been invited'
      end
    end
  end
end
