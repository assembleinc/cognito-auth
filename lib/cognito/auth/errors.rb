require 'aws-sdk-cognitoidentityprovider'
module Cognito
  module Auth
    module Errors
      class NoUserError < Aws::CognitoIdentityProvider::Errors::ServiceError
        def initialize(message = "User must be logged in.")
          super({},message)
        end
      end

      class NotAuthorizedError < Aws::CognitoIdentityProvider::Errors::ServiceError
        def initialize(message = "User is not authorized.")
          super({},message)
        end
      end
    end
  end
end
