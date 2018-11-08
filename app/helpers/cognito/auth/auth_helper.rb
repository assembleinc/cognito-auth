module Cognito
  module Auth
    module AuthHelper
      include Cognito::Auth::Helpers

      def with_cognito_catch
        yield
      rescue Aws::CognitoIdentityProvider::Errors::ServiceError => error
        flash[:danger] = t(error.class.to_s.demodulize.underscore)
        redirect_to cognito_auth.login_path
        return false
      end

      def current_user
        with_cognito_catch { Cognito::Auth.current_user }
      end

      def validate!
        with_cognito_catch { Cognito::Auth.validate! }
      end

      def authenticate(auth_parameters)
        with_cognito_catch {
          Cognito::Auth.authenticate(auth_parameters)
          if Cognito::Auth.logged_in
            redirect_to main_app.root_path
            return true
          else
            # have a challenge handler at that specific url
            flash[:warning] = t(Cognito::Auth.session[:challenge_name].downcase)
            redirect_to "#{cognito_auth.root_path}#{Cognito::Auth.session[:challenge_name].gsub('_','-').downcase}"
            return false
          end
        }
      end

      def respond_to_auth_challenge(challenge_responses)
        with_cognito_catch {
          Cognito::Auth.respond_to_auth_challenge(challenge_responses)
          if Cognito::Auth.logged_in
            redirect_to main_app.root_path
            return true
          else
            # have a challenge handler at that specific url
            redirect_to "#{cognito_auth.root_path}#{Cognito::Auth.session[:challenge_name].gsub('_','-').downcase}"
            return false
          end
        }
      end

      def log_out
        with_cognito_catch {
          Cognito::Auth.log_out
          redirect_to login_path
          return true
        }
      end

      def log_in(username,password)
        authenticate(USERNAME:username,PASSWORD:password)
      end

      def replace_temporary_password(newpass)
        respond_to_auth_challenge(USERNAME:Cognito::Auth.session[:username],NEW_PASSWORD:newpass)
      end

      def invite_user(email,group_name)
        @new_user = Cognito::Auth::User.user_exists?(email)
        @user = Cognito::Auth::User.new({email:email})
        unless @new_user
          @user.save
        else
          Cognito::Auth::ApplicationMailer.group_invite_email(@user).deliver_now
        end
        @user.reload!
        Cognito::Auth::Group.find(group_name).add_user(@user)
        @user
      end

    end
  end
end
