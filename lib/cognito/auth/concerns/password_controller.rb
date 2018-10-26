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
            redirect_to "#{cognito_auth.root_path}recover-password"
          }
        end

        def edit
        end

        def update
          with_cognito_catch {
            Cognito::Auth.recover_password(Cognito::Auth.session[:username], params[:user][:confirmation_code], params[:user][:password])
            flash[:success] = "Password Changed"
            redirect_to "#{cognito_auth.root_path}login"
          }
        end
      end
    end
  end
end
