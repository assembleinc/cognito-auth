module Cognito
  module Auth
    module Concerns
      module AuthHelper
        extend ActiveSupport::Concern

        def with_cognito_catch
          yield
        rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
          handle_service_error(error)
          return false
        end

        def current_user
          @current_user
        end

        def validate!
          with_cognito_catch do
            Cognito::Auth.validate!
            @current_user = Cognito::Auth.current_user
          end
        end

        def logged_in?
          Cognito::Auth.logged_in?
        end

        def authenticate(auth_parameters)
          with_cognito_catch do
            Cognito::Auth.authenticate(auth_parameters)
            if logged_in?
              after_login_success
              return true
            else
              handle_login_challenge
              return false
            end
          end
        end

        def respond_to_auth_challenge(challenge_responses)
          with_cognito_catch do
            Cognito::Auth.respond_to_auth_challenge(challenge_responses)
            if logged_in?
              after_login_success
              return true
            else
              # have a challenge handler at that specific url
              handle_login_challenge
              return false
            end
          end
        end

        def log_out
          with_cognito_catch do
            Cognito::Auth.log_out
            redirect_to login_path
            return true
          end
        end

        def log_in(username,password)
          authenticate(USERNAME: username, PASSWORD: password)
        end

        def replace_temporary_password(newpass)
          respond_to_auth_challenge(USERNAME: Cognito::Auth.session[:username], NEW_PASSWORD: newpass)
        end

        def after_login_success
          redirect_to main_app.root_path
        end

        def handle_login_challenge
          flash[:warning] = t(Cognito::Auth.session[:challenge_name].downcase, scope: 'cognito-auth')
          redirect_to "#{cognito_auth.root_path}#{Cognito::Auth.session[:challenge_name].gsub('_','-').downcase}"
        end

        def handle_service_error(error)
          if error.class == Aws::CognitoIdentityProvider::Errors::NotAuthorizedException && error.message === 'Password attempts exceeded'
            flash[:danger] = t(error.message.gsub(' ','_').downcase, scope: 'cognito-auth')
          else
            flash[:danger] = t(error.class.to_s.demodulize.underscore, scope: 'cognito-auth')
          end
          redirect_to cognito_auth.login_path
        end
      end
    end
  end
end
