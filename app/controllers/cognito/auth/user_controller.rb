module Cognito
  module Auth
    class UserController < ApplicationController
      include Cognito::Auth::Concerns::UserController
    end
  end
end
