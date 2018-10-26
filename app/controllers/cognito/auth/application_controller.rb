module Cognito
  module Auth
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      before_action :validate!
    end
  end
end
