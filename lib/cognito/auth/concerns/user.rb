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

          attr_accessor :mfa_options, :preferred_mfa_setting, :user_mfa_setting_list
          attr_reader :errors
          attribute :user_create_date, :date
          attribute :user_last_modified_date, :date
          attribute :enabled, :boolean
          attribute :user_status, :string

        end

        def initialize(attributes={})
          @errors = ActiveModel::Errors.new(self)
          user_attributes = self.class.parse_user(attributes)
          # add attributes from cognito
          # Cognito::Auth.schema_attributes.each do |name, attr|
          #   name = name.to_sym
          #   # if admin is accessing user add all schema_attributes otherwise only the readable and writable ones
          #   if !@is_current_user || self.class.client_attribute(name)
          #     # if you have defined the type of your custom attribute
          #     wocustom_name = name.to_s.delete_prefix('custom:').to_sym
          #     if name.to_s.include?('custom:') && Cognito::Auth.configuration.custom_attributes.key?(wocustom_name)
          #       self.class.attribute name, Cognito::Auth.configuration.custom_attributes[wocustom_name]
          #       self.class.alias_attribute wocustom_name, name
          #     else
          #       case attr.attribute_data_type
          #       when 'String'
          #         self.class.attribute wocustom_name, :string
          #       when 'Number'
          #         self.class.attribute wocustom_name, :cognito_int
          #       when 'Boolean'
          #         self.class.attribute wocustom_name, :cognito_bool
          #       end
          #     end
          #   else
          #     # if attribute isn't readable don't try and add it to user
          #     attributes.delete name
          #   end
          # end

          super(user_attributes)
          changes_applied

          # self.class.validates_each attributes.symbolize_keys.keys do |record, attr, value|
          #   record.errors.add attr, 'is not writable' if (changed.include?(attr.to_s) && !attribute_writable(attr))
          # end
        end

        def save
          # if @is_current_user
          #   Cognito::Auth.client.update_user_attributes(
          #     access_token: Cognito::Auth.session[:access_token],
          #     user_attributes: cognito_attributes
          #   )
          # else
            Cognito::Auth.client.admin_update_user_attributes(
              user_pool_id: Cognito::Auth.configuration.user_pool_id,
              username: username,
              user_attributes: cognito_attributes
            )
          # end
          changes_applied
          attributes
        end

        def groups(limit: nil, page: nil)
          params = { username: username, user_pool_id: Cognito::Auth.configuration.user_pool_id }
          params[:next_token] = page if page
          params[:limit] = limit if limit
          resp = Cognito::Auth.client.admin_list_groups_for_user(params)
          resp.groups.map { |group| Cognito::Auth::Group.new(group) }
        end

        def create(password:nil)
          username ||= send(Cognito::Auth.pool_description.username_attributes[0])
          unless self.class.user_exists?(username)
            params = {}
            params[:user_attributes] = cognito_attributes
            params[:user_pool_id] = Cognito::Auth.configuration.user_pool_id
            params[:username] = username
            params[:user_attributes].concat([{
              name: 'email_verified',
              value: Cognito::Auth.configuration.auto_verify_email.to_s
            }, {
              name: 'phone_number_verified',
              value: Cognito::Auth.configuration.auto_verify_phonenumber.to_s
            }])
            if password
              temppass = "temppass123**abc./"
              params[:message_action] = "SUPPRESS"
              params[:temporary_password] = temppass
            end
            Cognito::Auth.client.admin_create_user(params)
            if password
              # kind of hacky but here I just am replacing the temporary password with the given password
              auth_resp = Cognito::Auth.client.initiate_auth(auth_flow:"USER_PASSWORD_AUTH",auth_parameters: {USERNAME:username,PASSWORD:temppass},client_id: Cognito::Auth.configuration.client_id)
              Cognito::Auth.client.respond_to_auth_challenge(client_id:Cognito::Auth.configuration.client_id,challenge_name:auth_resp.challenge_name,session:auth_resp.session,challenge_responses:{USERNAME:username,NEW_PASSWORD:password})
            end
            reload!
          end

        end

        def delete
          Cognito::Auth.client.admin_delete_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id,
            username: username
          )
          attributes.each {|key,value| send(key+"=",nil)}
          changes_applied
        end

        def disable
          resp = Cognito::Auth.client.admin_disable_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id, # required
            username: username, # required
          )
          enabled = false
          changes_applied
        end

        def enable
          resp = Cognito::Auth.client.admin_enable_user(
            user_pool_id: Cognito::Auth.configuration.user_pool_id, # required
            username: username, # required
          )
          enabled = true
          changes_applied
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
          data = Cognito::Auth.get_user(username).attributes
          data.each {|key,value| send(key+"=",value)}
        end

        def cognito_attributes
          user_attributes = []
          attributes.extract!(*changed).each do |key, value|
            # if it is a valid user pool attribute that is mutable and isn't an alias for username and is valid to write by the client
            if attribute_writable(key)
              user_attributes.push(name: key, value: self.class.attribute_types[key].serialize(value))
            end
          end
          user_attributes
        end

        def attribute_writable(key)
          pool_attrs = Cognito::Auth.schema_attributes
          return pool_attrs.include?(key.to_s) && pool_attrs[key.to_s].mutable #&& (!@is_current_user || Cognito::Auth.write_attributes.include?(key.to_s))
        end

        class_methods do

          def parse_user(user)
            user = if user.is_a?(String)
              get_user_data(user)
            elsif user.is_a?(Hash)
              user
            else
              aws_struct_to_hash(user)
            end
            user.each do |attr, val|
              unless attribute_types.symbolize_keys.keys.include?(attr)
                user.delete attr
              end
            end
          end

          def client_attribute(name)
            Cognito::Auth.read_attributes.include?(name.to_s) || Cognito::Auth.write_attributes.include?(name.to_s)
          end

          def get_user_data(username)
            resp = Cognito::Auth.client.admin_get_user(
              user_pool_id: Cognito::Auth.configuration.user_pool_id,
              username: username
            )
            aws_struct_to_hash(resp)
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
