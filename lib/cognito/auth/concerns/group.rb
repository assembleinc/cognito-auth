module Cognito
  module Auth
    module Concerns
      module Group
        extend ActiveSupport::Concern
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Dirty

        included do
          attribute :description, :string
          attribute :role_arn, :string
          attribute :precedence, :integer
          attribute :group_name, :string
          attribute :creation_date, :date
          attribute :last_modified_date, :date
          attribute :user_pool_id, :string
          alias_attribute :name, :group_name
        end

        def initialize(group=nil)
          if group.is_a?(String)
            group = self.class.get_group_data(group)
          elsif group.is_a?(Struct)
            group = group.to_h
          elsif group.nil?
            group = {user_pool_id: Cognito::Auth.configuration.user_pool_id}
          end
          super(group)
          changes_applied
        end


        def create
          Cognito::Auth.client.create_group(attributes.symbolize_keys.extract!(:description, :role_arn, :precedence, :group_name, :user_pool_id))
          reload!
        end

        def delete
          users.each { |user| remove_user(user) }
          Cognito::Auth.client.delete_group(group_name:group_name,user_pool_id:user_pool_id)
        end

        def add_user(user)
          Cognito::Auth.client.admin_add_user_to_group(
            user_pool_id: Cognito::Auth.configuration.user_pool_id,
            username: self.class.get_username(user),
            group_name: group_name
          )
        end

        def remove_user(user)
          Cognito::Auth.client.admin_remove_user_from_group(
            user_pool_id: Cognito::Auth.configuration.user_pool_id,
            username: self.class.get_username(user),
            group_name: group_name
          )
        end

        def users(limit: nil, page: nil)
          params = { user_pool_id: Cognito::Auth.configuration.user_pool_id, group_name: group_name }
          params[:limit] = limit if limit
          params[:next_token] = page if page
          resp = Cognito::Auth.client.list_users_in_group(params)
          users = resp.users.map { |user_resp| Cognito::Auth::User.new(user_resp) }
          users
        end

        def save
          if changed?
            changed = self.changed
            Cognito::Auth.client.update_group(attributes.symbolize_keys.extract!(:description, :role_arn, :precedence, :group_name, :user_pool_id))
            changes_applied
            changed
          end
        end


        def rollback!
          restore_attributes
        end

        def reload!
          data = Cognito::Auth.get_group(group_name).attributes
          data.each {|key,value| send(key+"=",value)}
        end

        class_methods do

          def get_group_data(group_name)
            Cognito::Auth.client.get_group(
              group_name: group_name,
              user_pool_id: Cognito::Auth.configuration.user_pool_id
            ).group.to_h
          end

          def get_username(user)
            if user.is_a?(String)
              username = user
            elsif user.is_a?(Cognito::Auth::User)
              username = user.username
            elsif user.is_a?(Hash)
              username = user[:username]
            end
          end

        end
      end
    end
  end
end
