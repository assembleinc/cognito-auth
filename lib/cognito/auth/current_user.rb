require 'cognito/auth/helpers'
require 'aws-sdk-cognitoidentityprovider'
module Cognito
  module Auth
    module CurrentUser
      def authenticate(auth_parameters)
        flow = auth_parameters[:flow] || Cognito::Auth.configuration.default_log_in
        auth_parameters.delete :flow
        validation_data = auth_parameters[:validation_data] || {}
        auth_parameters.delete :validation_data
        resp = Cognito::Auth.client.initiate_auth(
          auth_flow: flow, # required, accepts USER_SRP_AUTH, REFRESH_TOKEN_AUTH, REFRESH_TOKEN, CUSTOM_AUTH, ADMIN_NO_SRP_AUTH, USER_PASSWORD_AUTH
          auth_parameters: auth_parameters,
          client_metadata: validation_data, # shows up in preauth lambda function as event.request.validationData
          client_id: Cognito::Auth.configuration.client_id, # required
        )
        log_in_if_authorized(resp)
      end

      def respond_to_auth_challenge(challenge_responses)
        resp = Cognito::Auth.client.respond_to_auth_challenge(
          client_id: Cognito::Auth.configuration.client_id,
          challenge_name: Cognito::Auth.session[:challenge_name],
          session: Cognito::Auth.session[:session_token],
          challenge_responses: challenge_responses,
        )
        log_in_if_authorized(resp)
      end

      def log_in(username, password, validation_data: {})
        authenticate(USERNAME: username, PASSWORD: password, flow: 'USER_PASSWORD_AUTH', validation_data: validation_data)
      end

      def replace_temporary_password(username, new_pass)
        respond_to_auth_challenge(USERNAME: username, NEW_PASSWORD: new_pass)
      end

      def log_out
        @current_user = nil
        @logged_in = false
        begin
          Cognito::Auth.client.global_sign_out(
            access_token: Cognito::Auth.session[:access_token]
          )
        rescue Aws::CognitoIdentityProvider::Errors::ServiceError, ArgumentError
          # if access tokens exist or are revoked we will get errors
          # since this would mean that the user is already logged out
          # we will disregard this error
        end
        unless Cognito::Auth.session_destroy.nil?
          Cognito::Auth.session_destroy.delete :access_token
          Cognito::Auth.session_destroy.delete :refresh_token
          Cognito::Auth.session_destroy.delete :id_token
          Cognito::Auth.session_destroy.delete :token_expires
        end
        !@logged_in
      end

      def send_verification_code(attribute)
        if validate!
          Cognito::Auth.client.get_user_attribute_verification_code(
            access_token: Cognito::Auth.session[:access_token],
            attribute_name: attribute.to_s
          )
        end
      end

      def verify_attribute(attribute,confirmation_code)
        if validate!
          Cognito::Auth.client.verify_user_attribute(
            access_token: Cognito::Auth.session[:access_token], # required
            attribute_name: attribute.to_s, # required
            code: confirmation_code.to_s # required
          )
          @current_user.reload!
        end
      end

      def change_password(prevpass, newpass)
        if validate!
          Cognito::Auth.client.change_password(
            previous_password: prevpass,
            proposed_password: newpass,
            access_token: Cognito::Auth.session[:access_token]
          )
        end
      end

      def forgot_password(username)
        Cognito::Auth.client.forgot_password(
          client_id: Cognito::Auth.configuration.client_id, # required
          username: username, # required
        )
      end

      def recover_password(username, confirmation_code, password)
        Cognito::Auth.client.confirm_forgot_password(
          client_id: Cognito::Auth.configuration.client_id, # required
          username: username, # required
          confirmation_code: confirmation_code.to_s, # required
          password: password, # required
        )
      end

      def current_user
        if @logged_in
          @current_user ||= Cognito::Auth::User.init_model(Cognito::Auth::User.get_current_user_data)
        else
          nil
        end
      rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
        nil
      end

      def validate!
        if Cognito::Auth.session[:access_token] && Cognito::Auth.session[:token_expires] && Cognito::Auth.session[:refresh_token]
          if Time.now.to_i > Cognito::Auth.session[:token_expires].to_i
            return authenticate(REFRESH_TOKEN: Cognito::Auth.session[:refresh_token], flow:'REFRESH_TOKEN_AUTH')
          else
            @current_user = Cognito::Auth::User.init_model(Cognito::Auth::User.get_current_user_data)
            allowed_groups = Cognito::Auth.configuration.allowed_groups
            if allowed_groups.empty? || @current_user.groups.any? { |group| allowed_groups.include?(group.group_name) }
              @logged_in = true
              return true
            else
              log_out
              raise Cognito::Auth::Errors::NotAuthorizedError
              return false
            end
          end
        else
          raise Cognito::Auth::Errors::NoUserError
          return false
        end
      end

      protected

      def store_access_tokens(resp)
        auth_tokens = resp['authentication_result']
        Cognito::Auth.session[:access_token] = auth_tokens['access_token'] # used for any aws-sdk methods
        Cognito::Auth.session[:id_token] = auth_tokens['id_token'] # used for http authorization in appsync calls # when using the refresh token the result doesn't return with a new refresh token
        if auth_tokens['refresh_token']
          Cognito::Auth.session[:refresh_token] = auth_tokens['refresh_token'] # used to update an expired token
        end
        Cognito::Auth.session[:token_expires] = Time.now.to_i + Cognito::Auth.configuration.token_refresh_rate # sets local expiration time for token, token will have revoked access to cognito sdk functions after this time
      end

      def log_in_if_authorized(resp)
        unless resp.challenge_name.nil?
          Cognito::Auth.session[:challenge_name] = resp.challenge_name
          Cognito::Auth.session[:session_token] = resp.session
          @logged_in = false
        else
          store_access_tokens(resp)
          validate!
        end
      end

    end
  end
end
