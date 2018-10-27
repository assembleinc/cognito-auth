module Cognito
  module Auth
    class ApplicationMailer < ActionMailer::Base
      default from: Cognito::Auth.configuration.mail_from
      layout 'mailer'

      def invite_email(user, temporary_password)
        @user = user
        @temporary_password = temporary_password
        mail(to: @user.email, subject: Cognito::Auth.configuration.mail_subject)
      end
    end
  end
end
