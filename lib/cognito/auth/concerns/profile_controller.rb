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
            @user = params[:user]
            @user.save
            redirect_to "#{cognito_auth.root_path}profile"
        end

        def update_password
          with_cognito_catch {
            Cognito::Auth.change_password(params[:oldpass],params[:newpass])
          }
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
