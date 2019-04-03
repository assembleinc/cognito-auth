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
          if Cognito::Auth::User.user_exists?(params[:user][:email])
            user = Cognito::Auth::User.find(params[:user][:email])
            if user.user_status == 'CONFIRMED'
              Cognito::Auth.session[:username] = user.username
              Cognito::Auth.forgot_password(Cognito::Auth.session[:username])
              flash[:success] = t('recovery_code_sent', scope: 'cognito-auth')
              redirect_to recover_password_path
            elsif user.user_status == 'FORCE_CHANGE_PASSWORD'
              user.reset
              flash[:success] = t('new_temporary_password_sent', scope: 'cognito-auth')
              redirect_to login_path
            end
          else
            flash[:danger] = t('email_not_found', scope: 'cognito-auth')
            redirect_back(fallback_location: login_path)
          end
        rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
          flash[:danger] = t(error.class.to_s.demodulize.underscore, scope: 'cognito-auth')
          redirect_back(fallback_location: login_path)
        end

        def edit
        end

        def update
          Cognito::Auth.recover_password(Cognito::Auth.session[:username], params[:user][:confirmation_code], params[:user][:password])
          flash[:success] = t('password_changed', scope: 'cognito-auth')
          redirect_to login_path
        rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
          flash[:danger] = t(error.class.to_s.demodulize.underscore, scope: 'cognito-auth')
          redirect_back(fallback_location: login_path)
        end
      end
    end
  end
end
