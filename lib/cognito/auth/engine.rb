module Cognito
  module Auth
    class Engine < ::Rails::Engine
      isolate_namespace Cognito::Auth
      engine_name 'cognito_auth'

      config.to_prepare do
        Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
          require_dependency(c)
        end

        ActiveSupport.on_load(:action_controller) do
          include Cognito::Auth::AuthHelper
        end

        ActiveSupport.on_load(:action_view) do
          include Cognito::Auth::AuthHelper
        end
      end
    end
  end
end
