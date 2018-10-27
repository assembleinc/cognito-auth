module Cognito
  module Auth
    module Concerns
      module AdminController
        extend ActiveSupport::Concern
        included do
          layout 'cognito/auth/application'
        end

        def index
          @users = Cognito::Auth::User.find_all
        end
      end
    end
  end
end
