require 'json'
require 'active_support'
module Cognito
  module Auth
    module Helpers
      def merge_on_field(a, b, field)
        b.select { |elema| a.none? { |elemb| elemb[field] == elema[field] } } + a
      end

      def aws_object_array_to_hash(list)
        attrs = {}
        list.each do |attr|
          attrs[attr.name] = attr
        end
        attrs
      end
    end
  end
end
