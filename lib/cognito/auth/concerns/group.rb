module Cognito
  module Auth
    module Concerns
      module Group
        extend ActiveSupport::Concern
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Dirty

        included do
          attr_accessor :new_record
          attribute :description, :string
          attribute :role_arn, :string
          attribute :precedence, :integer
          attribute :group_name, :string
          attribute :creation_date, :date
          attribute :last_modified_date, :date
          attribute :user_pool_id, :string
          alias_attribute :name, :group_name
        end

        def initialize(*args)
          @new_record = true
          super(*args)
        end

        def save
          group_attrs = attributes.symbolize_keys.extract!(:description, :role_arn, :precedence, :group_name)
          group_attrs[:user_pool_id] = Cognito::Auth.configuration.user_pool_id
          if @new_record
            Cognito::Auth.client.create_group(group_attrs)
          elsif changed?
            Cognito::Auth.client.update_group(group_attrs)
          end
          reload!
          changes_applied
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
          users = resp.users.map { |user_resp| Cognito::Auth::User.init_model(user_resp.to_h) }
          users
        end

        def rollback!
          restore_attributes
        end

        def reload!
          data = self.class.get_group_data(group_name)
          data.each {|key,value| send(key.to_s+"=",value)}
        end

        class_methods do

          def find(group_name)
            group = init_model(get_group_data(group_name))
          end

          def find_all
            params = { user_pool_id: Cognito::Auth.configuration.user_pool_id }
            resp = Cognito::Auth.client.list_groups(params)
            resp.groups.map { |group| init_model(group.to_h) }
          end

          def get_group_data(group_name)
            Cognito::Auth.client.get_group(
              group_name: group_name,
              user_pool_id: Cognito::Auth.configuration.user_pool_id
            ).group.to_h
          end

          def init_model(item)
            item = self.new(item)
            item.new_record = false
            item.changes_applied
            item
          end

          def get_username(user)
            if user.is_a?(String)
              username = Cognito::Auth::User.find(user).username
            elsif user.is_a?(Cognito::Auth::User)
              username = user.username
            end
          end

        end
      end
    end
  end
end
