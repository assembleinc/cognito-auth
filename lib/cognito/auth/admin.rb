require 'cognito/auth/helpers'
module Cognito
  module Auth
    module Admin
      extend Cognito::Auth::Helpers

      def get_user(username)
        Cognito::Auth::User.new(username)
      end

      def get_group(group_name)
        Cognito::Auth::Group.new(group_name)
      end

      def get_users(limit: nil, page: nil)
        params = { user_pool_id: Cognito::Auth.configuration.user_pool_id }
        params[:limit] = limit if limit
        params[:pagination_token] = page if page
        resp = Cognito::Auth.client.list_users(params)
        resp.users.map { |user_resp| Cognito::Auth::User.new(user_resp) }
      end

      def get_groups(limit: nil, page: nil)
        params = { user_pool_id: Cognito::Auth.configuration.user_pool_id }
        params[:limit] = limit if limit
        params[:next_token] = page if page
        resp = Cognito::Auth.client.list_groups(params)
        resp.groups.map { |group| Cognito::Auth::Group.new(group) }
      end

    end
  end
end
