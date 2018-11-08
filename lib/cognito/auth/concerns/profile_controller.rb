module Cognito
  module Auth
    module Concerns
      module ProfileController
        extend ActiveSupport::Concern

        included do
          layout 'cognito/auth/application'
        end

        def edit
          @user = current_user
        end

        def update
          @user = current_user
          @user.update(params[:user])
          @user.save

          unless params[:user][:password].to_s.empty? || params[:user][:proposed_password].to_s.empty?
            begin
              Cognito::Auth.change_password(params[:user][:password],params[:user][:proposed_password])
            rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
              flash[:danger] = t('incorrect_password')
            end
          end
          redirect_to profile_path
        end

        def send_email_verification
          with_cognito_catch {
            Cognito::Auth.send_verification_code("email")
          }
        end

        def verify_email
          with_cognito_catch {
             Cognito::Auth.verify_attribute("email",params[:confirmation_code])
           }
        end

        def send_phone_number_verification
          with_cognito_catch {
            Cognito::Auth.send_verification_code("phone_number")
          }
        end

        def verify_phonenumber
          with_cognito_catch {
             Cognito::Auth.verify_attribute("phone_number",params[:confirmation_code])
           }
        end
      end
    end
  end
end
