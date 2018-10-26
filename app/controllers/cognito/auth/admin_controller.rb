module Cognito
  module Auth
    class AdminController < ApplicationController
      include Cognito::Auth::Concerns::AdminController
    end
  end
end
