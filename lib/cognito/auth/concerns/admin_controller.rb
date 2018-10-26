module Cognito
  module Auth
    module AdminController
      extend ActiveSupport::Concern
      included do
        layout 'cognito/auth/application'
      end
    end
  end
end
