module Cognito
  module Auth
    class ProfileController < ApplicationController
      include Cognito::Auth::Concerns::ProfileController
    end
  end
end
