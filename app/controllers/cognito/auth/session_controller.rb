module Cognito
  module Auth
    class SessionController < ApplicationController
      include Cognito::Auth::Concerns::SessionController
    end
  end
end
