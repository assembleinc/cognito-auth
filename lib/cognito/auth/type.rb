require 'json'
require 'active_model'
module Cognito
  module Auth
    module Type
      class Json < ActiveModel::Type::Value
        def type
          :cognito_json
        end

        def cast(obj)
          if obj.is_a?(String)
            JSON.parse(obj)
          else
            obj
          end
        end

        def serialize(obj)
          JSON.unparse(obj)
        end
      end

      class Boolean < ActiveModel::Type::Boolean
        def type
          :cognito_bool
        end

        def serialize(obj)
          obj.to_s
        end
      end

      class Integer < ActiveModel::Type::Integer
        def type
          :cognito_int
        end

        def serialize(obj)
          obj.to_s
        end
      end
    end
  end
end

ActiveModel::Type.register(:cognito_bool, Cognito::Auth::Type::Boolean)
ActiveModel::Type.register(:cognito_int, Cognito::Auth::Type::Integer)
ActiveModel::Type.register(:cognito_json, Cognito::Auth::Type::Json)
