module Cognito
  module Auth
    class PasswordController < ApplicationController
      include Cognito::Auth::Concerns::PasswordController
    end
  end
end
