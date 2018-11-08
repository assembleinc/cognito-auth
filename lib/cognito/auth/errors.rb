require 'aws-sdk-cognitoidentityprovider'
module Cognito
  module Auth
    module Errors
      class NoUserError < Aws::CognitoIdentityProvider::Errors::ServiceError
        def initialize(message = t('no_user_error', scope: 'cognito-auth'))
          super({},message)
        end
      end

      class NotAuthorizedError < Aws::CognitoIdentityProvider::Errors::ServiceError
        def initialize(message = t('not_authorized_error', scope: 'cognito-auth'))
          super({},message)
        end
      end
    end
  end
end
