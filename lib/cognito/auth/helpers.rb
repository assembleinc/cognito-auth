require 'json'
require 'active_support'
module Cognito
  module Auth
    module Helpers
      extend ActiveSupport::Concern
      def aws_object_array_to_hash(list)
        attrs = {}
        list.each do |attr|
          attrs[attr.name] = attr
        end
        attrs
      end

      def get_objects(params, limit: nil, page: nil, token: :next_token, &fetch)
        all_results = []
        limit = limit.nil? ? 60 : limit
        offset = page.nil? ? 0 : (page - 1)*limit
        while offset > 0
          qnum = [offset, 60].min
          offset -= qnum
          params[:limit] = qnum
          objects, params[token] = fetch.call(params)
        end
        while limit > 0
          qnum = [limit, 60].min
          limit -= qnum
          params[:limit] = qnum
          objects, params[token] = fetch.call(params)
          all_results.concat(objects)
        end
        all_results
      end
    end
  end
end
