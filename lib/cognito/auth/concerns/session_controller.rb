module Cognito
  module Auth
    module Concerns
      module SessionController
        extend ActiveSupport::Concern
        included do
          layout 'cognito/auth/application'
          skip_before_action :validate!
        end

        def new
        end

        def create
          # if login is not successful keep track of username
          Cognito::Auth.session[:username] = params[:user][:username] unless log_in(params[:user][:username],params[:user][:password])
        end

        def destroy
          log_out
        end

        def auth
          authenticate(params[:auth_params])
        end

        def edit_password
        end

        def update_password
          replace_temporary_password(params[:user][:password])
        end

      end
    end
  end
end
