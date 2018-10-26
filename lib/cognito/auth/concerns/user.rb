require 'cognito/auth/helpers'
require 'active_model'
module Cognito
  module Auth
    module Concerns
      module User
        extend Cognito::Auth::Helpers
        extend ActiveSupport::Concern
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Dirty
        include ActiveModel::Serializers
        include ActiveModel::AttributeMethods
        include ActiveModel::Validations

        included do
          attribute :username, :string
          attribute :email, :string
          attribute :email_verified, :cognito_bool
          attribute :name, :string

          attr_accessor :mfa_options, :preferred_mfa_setting, :user_mfa_setting_list, :new_record
          attr_reader :errors
          attribute :user_create_date, :date
          attribute :user_last_modified_date, :date
          attribute :enabled, :boolean
          attribute :user_status, :string
          attribute :new_pass, :string
        end

        def initialize(*args)
          @errors = ActiveModel::Errors.new(self)
          @new_record = true
          super(*args)
        end

        def save
          username ||= send(Cognito::Auth.pool_description.username_attributes[0])
          if @new_record
            unless self.class.user_exists?(username)
              params = {}
              params[:username] = username
              params[:user_attributes] = cognito_attributes
              params[:user_pool_id] = Cognito::Auth.configuration.user_pool_id
              params[:user_attributes].concat([{
                name: 'email_verified',
                value: Cognito::Auth.configuration.auto_verify_email.to_s
              }, {
                name: 'phone_number_verified',
                value: Cognito::Auth.configuration.auto_verify_phonenumber.to_s
              }])
              unless new_pass.nil?
                temppass = "temppass123**abc./"
                params[:message_action] = "SUPPRESS"
                params[:temporary_password] = temppass
              end
              Cognito::Auth.client.admin_create_user(params)
              unless new_pass.nil?
                # kind of hacky but here I just am replacing the temporary password with the given password
                auth_resp = Cognito::Auth.client.initiate_auth(auth_flow:"USER_PASSWORD_AUTH",auth_parameters: {USERNAME:username,PASSWORD:temppass},client_id: Cognito::Auth.configuration.client_id)
                Cognito::Auth.client.respond_to_auth_challenge(client_id:Cognito::Auth.configuration.client_id,challenge_name:auth_resp.challenge_name,session:auth_resp.session,challenge_responses:{USERNAME:username,NEW_PASSWORD:new_pass})
              end
            else
              @errors.add(:username, :invalid, message: "User already exists")
            end
          else
            Cognito::Auth.client.admin_update_user_attributes(
              user_pool_id: Cognito::Auth.configuration.user_pool_id,
              username: username,
              user_attributes: cognito_attributes
            )
          end
          changes_applied
          reload!
        end

        def groups(limit: nil, page: nil)
          params = { username: username, user_pool_id: Cognito::Auth.configuration.user_pool_id }
          params[:next_token] = page if page
          params[:limit] = limit if limit
          resp = Cognito::Auth.client.admin_list_groups_for_user(params)
          resp.groups.map { |group| Cognito::Auth::Group.init_model(group.to_h) }
        end

        def delete
          Cognito::Auth.client.admin_delete_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id,
            username: username
          )
          attributes.each {|key,value| send(key+"=",nil)}
          reload!
        end

        def disable
          resp = Cognito::Auth.client.admin_disable_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id, # required
            username: username, # required
          )
          reload!
        end

        def enable
          resp = Cognito::Auth.client.admin_enable_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id, # required
            username: username, # required
          )
          reload!
        end

        def reset_password
          Cognito::Auth.client.admin_reset_user_password(
            user_pool_id: Cognito::Auth.configuration.user_pool_id, # required
            username: username, # required
          )
        end

        def global_log_out
          Cognito::Auth.client.admin_user_global_sign_out(
            user_pool_id: Cognito::Auth.configuration.user_pool_id,
            username: username
          )
        end

        def reload!
          data = self.class.parse_attrs(self.class.get_user_data(username))
          data.each {|key,value| send(key.to_s+"=",value)}
        end

        def cognito_attributes
          user_attributes = []
          attributes.extract!(*changed).each do |key, value|
            if attribute_writable(key)
              user_attributes.push(name: key, value: self.class.attribute_types[key].serialize(value))
            end
          end
          user_attributes
        end

        def attribute_writable(key)
          pool_attrs = Cognito::Auth.schema_attributes
          return pool_attrs.include?(key.to_s) && pool_attrs[key.to_s].mutable
        end

        class_methods do

          def find(username)
            init_model(get_user_data(username))
          end

          def find_all
            params = { user_pool_id: Cognito::Auth.configuration.user_pool_id }
            resp = Cognito::Auth.client.list_users(params)
            resp.users.map { |user_resp| init_model(aws_struct_to_hash(user_resp)) }
          end

          def init_model(item)
            parse_attrs(item)
            item = self.new(item)
            item.new_record = false
            item.changes_applied
            item
          end

          def get_user_data(username)
            resp = Cognito::Auth.client.admin_get_user(
              user_pool_id: Cognito::Auth.configuration.user_pool_id,
              username: username
            )
            aws_struct_to_hash(resp)
          end

          def parse_attrs(user)
            user.each do |attr, val|
              unless attribute_types.symbolize_keys.keys.include?(attr)
                user.delete attr
              end
            end
            user
          end

          def get_current_user_data
            resp = Cognito::Auth.client.get_user(
              access_token: Cognito::Auth.session[:access_token]
            )
            aws_struct_to_hash(resp)
          end

          def client_attribute(name)
            Cognito::Auth.read_attributes.include?(name.to_s) || Cognito::Auth.write_attributes.include?(name.to_s)
          end

          def user_exists?(username)
            get_user_data(username)
            true
          rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
            false
          end

          def aws_attribute_array_to_hash(list)
            attrs = {}
            list.each do |attr|
              attr.name.delete_prefix!('custom:')
              attrs[attr.name.to_sym] = attr.value
            end
            attrs
          end

          def aws_struct_to_hash(resp)
            user = {}
            # add all attributes other than user_attributes
            resp.members.each do |member|
              unless %i[user_attributes attributes].include?(member)
                user[member] = resp[member]
              end
            end
            # merge in all user attributes
            if resp.members.include? :user_attributes
              user = user.merge(aws_attribute_array_to_hash(resp[:user_attributes]))
            elsif resp.members.include? :attributes
              user = user.merge(aws_attribute_array_to_hash(resp[:attributes]))
            end
            user
          end
        end
      end
    end
  end
end
