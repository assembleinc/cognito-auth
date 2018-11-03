module Cognito
  module Auth
    module Concerns
      module PasswordController
        extend ActiveSupport::Concern

        included do
          layout 'cognito/auth/application'
          skip_before_action :validate!
        end

        def new
        end

        def create
          with_cognito_catch {
            Cognito::Auth.session[:username] = Cognito::Auth::User.find(params[:user][:email]).username
            Cognito::Auth.forgot_password(Cognito::Auth.session[:username])
            flash[:success] = "Recovery Code Sent"
            redirect_to recover_password_path
          }
        end

        def edit
        end

        def update
          Cognito::Auth.recover_password(Cognito::Auth.session[:username], params[:user][:confirmation_code], params[:user][:password])
          flash[:success] = "Password Changed"
          redirect_to login_path
        rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
          flash[:danger] = error.message
          redirect_back(fallback_location: root_path)
        end
      end
    end
  end
end
