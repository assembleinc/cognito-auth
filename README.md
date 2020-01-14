# Cognito::Auth
Allows one to quickly boot up a rails application using Amazon Cognito as a login authentication service
Converts AWS struct objects returned by the aws-sdk into Active Model objects

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'cognito-auth', git: 'https://github.com/assemble-inc/cognito-auth.git', tag: '0.6.0'
```

Mount the gem in your project routes:

```ruby
mount Cognito::Auth::Engine, at: "auth"
```

In any controllers that require the user to be logged in add:
```ruby
before_action :validate!
```

Now if the user is not logged in they will be redirected to  `/auth/login`

In your initializers add the code:
```ruby
Cognito::Auth.configure do |config|
  config.user_pool_id = 'user pool id'
  config.client_id = 'client id'
  config.user_pool_region = 'user pool region'
end

Cognito::Auth.module_eval do
  def self.verify(payload)
    # any custom validations you want to apply to the user
  end
end

Aws.config.update({
   credentials: Aws::Credentials.new('key id', 'secret access key')
})

```

Other configuration parameters include:
- `token_refresh_rate`: how often the access token will refresh, defaults to 1 hour
- `auto_verify_email`: if set to true newly created users will have their email already verified
- `auto_verify_phonenumber`: if set to true newly created users will have their phone number already verified
- `default_log_in`: default log in flow used by authenticate method, defaults to `USER_PASSWORD_AUTH`
- `mail_from`: the email address that invites to your application will use
- `mail_subject`: subject for invitation emails

Edit the Rails credentials to store `user_pool_id`, `client_id` and `user_pool_region`
example: `env EDITOR="nano" rails credentials:edit`

To set up the mailer either set
  `config.action_mailer.default_url_options { host: your-base-url }` in config/environments
or overwrite views/cognito/auth/application_mailer/invite_email.html.erb

## Cognito::Auth Module core methods

+ User Methods
  - authenticate(auth_parameters)
    - auth_parameters: {
      flow: The authentication flow method accepts USER_SRP_AUTH, REFRESH_TOKEN_AUTH, REFRESH_TOKEN, CUSTOM_AUTH, ADMIN_NO_SRP_AUTH, USER_PASSWORD_AUTH
      validation_data: custom data sent to the authentication lambda function used for any CUSTOM_AUTH
      Any remaining parameters required for the particular authentication flow.
    }
    - calls https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#admin_initiate_auth-instance_method

    - If authentication responds with a challenge it will store the challenge_name and session_token in cookies.
    - Otherwise it will store access_token, refresh_token, id_token, and token_expires in cookies and checks the id_token payload for the correct issuer and audience.
    - Then calls verify which can be overwritten to verify the token against the payload
    - If verification fails it will clear all cookies related to cognito auth

  - respond_to_auth_challenge(challenge_responses)
    - challenge_responses: any parameters required to respond to the current auth challenge defined in the `challenge_name` cookie (which should have been set when you called authenticate)
    - calls https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#admin_respond_to_auth_challenge-instance_method
    - performs the same actions as authenticate

  - log_in(username, password, validation_data:{})
    - calls authenticate with the 'USER_PASSWORD_AUTH' flow

  - replace_temporary_password(username, new_pass)
    - calls respond to auth challenge with specific username and password
    - to be used against the `NEW_PASSWORD_REQUIRED` challenge

  - log_out
    - sets clears current_user, deletes all Cognito related tokens

  - send_verification_code(attribute)
    - given an attribute `:email` or `:phone_number` emails a verification code to the current user with https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#get_user_attribute_verification_code-instance_method

  - verify_attribute(attribute, confirmation_code)
    - verifies the given attribute for the current user with the confirmation code emailed to the user

  - change_password(prevpass, newpass)
    - changes the current user's password

  - forgot_password(username)
    - sends a forgot_password email with a password recovery code to the given user.
    - username can be any verified username_alias attributes such as `username`, `email` or `phone number`

  - recover_password(username, confirmation_code, password)
    - changes the user's password based off the confirmation code emailed to them

  - current user
    - if logged in it will return the current user model otherwise returns nil

  - validate!
    - checks if access tokens are still valid and non expired
    - calls the verify function on the id_token payload for custom verifications

  - verify(payload)
    - by default always returns true
    - overwrite this method for custom validations against the id token payload every time validate is called

+ client methods
  - client
    - returns the client defined here: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html

  - pool_description
    - returns a description of the user pool defined here: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#describe_user_pool-instance_method

  - schema_attributes
    - returns a hash containing all schema_attributes in the pool description

  - client_description
    - returns a description of the client defined here: https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#describe_user_pool_client-instance_method

  - write_attributes
    - returns the attributes the client is allowed to write to (if not using admin functions)

  - read_attributes
    - returns the attributes the client is allowed to read (if not using admin functions)
+ general methods
  - version
    - returns cognito auth version

  - configuration
    - holds all project configuration data

  - session
    - allows access to session variables set during authentication

  - errors
    - ActiveModel::Errors used in the session controller

## Routes
```ruby
root to: 'session#new'
get  '/login', to: "session#new"
post '/login', to: "session#create"
get  '/new-password-required', to: "session#edit_password"
post '/new-password-required', to: "session#update_password"
delete '/logout', to: "session#destroy"


get  '/forgot-password', to: "password#new"
post '/forgot-password', to: "password#create"
get  '/recover-password', to: "password#edit"
post '/recover-password', to: "password#update"
```

## Models
+ User Instance Methods
  - Includes Active Model
  - save
    - saves the user and creates them if they don't exist
  - groups(limit: nil, page: nil)
    - gets the user's groups given a limit and page
    - cognito only allows max limit of 60 and pagination with next_tokens so to work around this:
      - if limit is set over 60 multiple queries will execute to get the result
      - if page is set a set of queries will execute to find the first group, and then a set of queries will execute to return the groups
      - if neither are set it will just return the first 60 results with one query

  - delete
    - deletes the user from cognito entirely and whipes the data in the user object

  - disable
    - disables the user in cognito so they are not allowed to log in or perform any actions

  - enable
    - reenable's the user

  - reset_password
    - resets the users password sending them an email with a confirmation code, same as using forgot password on them

  - global_log_out
    - invalidates all of the users access, id and refresh tokens

  - reload!
    - pulls the user data from cognito

  - update(params)
    - sets the user attributes to those defined in params

  - reset
    - if the user_status is `FORCE_CHANGE_PASSWORD` it will delete the user and create a new user instance with all the same groups and attributes, which will send them a new temporary password

  - change_password(password:"", proposed_password:"", confirm_password:"", confirm_password_required: true)
    - only valid to call on current user
    - sets their password to proposed password if password is correct
    - requires either confirm_password_required to be false or confirm_password to equal proposed password
    - stores any errors in `Cognito::Auth.errors`

  - full_name
    - returns `first_name last_name`

  - human_name
    - returns one of full_name, first_name or email if defined prioritizing in that order

  - ==(other)
    - checks if other has the same username as the user

+ User Class Methods
  - find(username)
    - returns the user model relating to the specific username
    - valid usernames are whichever username_aliases are set up for your project, one of: `email`, `phone_number` or `username`
    - if no user is found a `Aws::CognitoIdentityProvider::Errors::UserNotFoundException` is thrown

  - all(limit:nil, page: nil, filter: nil)
    - returns all users in user pool with https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/CognitoIdentityProvider/Client.html#list_users
    - runs a query to collect every 60 results
    - runs a query for every page until you find the correct result

  - new(attributes)
    - creates a new User object with attributes

  - init_model(attributes)
    - initializes a User object from a attributes and flags it as not a new object

  - get_user_data(username)
    - returns a hash of attributes for a user with a specific username
    - returns nil if user doesn't exist

  - get_current_user_data
    - returns a hash of attributes for the current user
    - returns nil if current user doesn't exist

  - user_exists?(username)
    - probabaly inefficient to use this method but queries for user data and returns true if the user exists and false given a cognito error

+ Group Instance Methods
  - Includes Active Model
  - save
    - saves the group, creating a new one if it doesn't exist in cognito

  - delete
    - deletes the group from cognito

  - add_user(user)
    - user can be a `username`, user object or username alias such as `email` or `phone_number`
    - adds the user to the group

  - remove_user(user)
    - user can be a `username`, user object or username alias such as `email` or `phone_number`
    - removes the user to the group

  - invite_user(email)
    - sends the user a `group_invite_email` defined in Cognito::Auth::ApplicationMailer
    - adds the user to the group
    - if the user doesn't exist it will create them and add them to the group

  - resend_invite(email, reset:false)
    - if reset is set to true and the user hasn't set their password yet, then it will delete the user, and create a new user instance with the same attributes and send them an email with a new temporary_password
    - otherwise it sends the user a `group_invite_email` defined in Cognito::Auth::ApplicationMailer
    - adds the user to the group
    - if the user doesn't exist it will create them and add them to the group

  - create_and_add_user(email)
    - creates a new user with the specified email and adds them to the group
  - users(limit: nil, page: nil)
    - lists the users in the group
    - limit defaults to 60
    - does a query to collect every 60 results
    - does a query for every page of 60 results till it retrieves the correct page

  - rollback!
    - restores_attributes to state that you fetched them at

  - reload!
    - pulls group data in from cognito

  - ==(other)
    - checks for equality based off group name

+ Group Class Methods
  - find(group_name)
    - gets a group by group name

  - all(limit: nil, page: nil)
    - lists all groups in the user pool
    - limit defaults to 60
    - does a query to collect every 60 results
    - does a query for every page of 60 results till it retrieves the correct page

  - get_group_data(group_name)
    - returns a hash of group data for a group

  - new(attributes)
    - creates a new group instance from attributes

  - init_model(attributes)
    - creates a new group instance from attributes and flags them as not a new record

## Locales

Flash notices are created with i18n keys. Any errors will have the key `cognito-auth.{Error Name in camel case}`.
A full list of Cognito errors can be found here: https://docs.aws.amazon.com/sdkforruby/api/Aws/CognitoIdentityProvider/Errors.html
+ Specifically these ones show up in the login flow:
  - `cognito-auth.not_authorized_exception` (Cognito Authentication failed)
  - `cognito-auth.user_not_found_exception` (User is not part of the user pool)
  - `cognito-auth.code_mismatch_exception` (Password recovery code does not match the one sent in the email)
  - `cognito-auth.invalid_password_exception` (New password doesn't fit the password criteria)

+ Gem specific errors:
  - `cognito-auth.no_user_error` (for when someone tries to access the application while not logged in)
  - `cognito-auth.not_authorized_error` (for when someone tries to log in and is not part of the correct cognito groups to access the application)

+ Authorization challenges will have the key `cognito-auth.{challenge name downcased}`
  - `cognito-auth.new_password_required` (Warning that shows on the new password required page)

+ Additional locales that you need to set are:
  - `cognito-auth.password_changed` (When a password is changed through the forgot password flow)
  - `cognito-auth.email_not_found` (When forgot password is attempted but the specified email is not part of the userpool)
  - `cognito-auth.recovery_code_sent` (When an email is sent through the forgot password flow)
  - `cognito-auth.new_temporary_password_sent` (When a user goes through the forgot password flow but hasn't set their password yet and a new temporary password is sent)

## External Data Source

If you would like to pull user data form another place other than cognito just extend the user model with forwardable

Example: in `models/cognito/auth/user.rb` to pull from a Mongoid document called UserProperties that stores user's username and a boolean called admin
```ruby
module Cognito
  module Auth
    class User
      include Cognito::Auth::Concerns::User
      extend Forwardable

      attr_accessor :user_properties
      def_delegators :user_properties, :admin, :admin=

      def user_properties
        @user_properties ||= ::UserProperties.find_by(username: username)
      rescue
        ::UserProperties.new(username: username)
      end

      def save
        super
        user_properties.save
      end
    end
  end
end
```

## Overwrite
+ Controllers
  - create a new file `controllers/cognito/auth/{controller_to_overwite}.rb`

  ```ruby
  module Cognito
    module Auth
      class {ControllerToOverwrite} < ApplicationController
        include Cognito::Auth::Concerns::{ControllerToOverwrite}
        def {method_to_extend}
          super()
          # your code
        end
  ```

+ Models
  - create a new file `models/cognito/auth/{model_to_overwrite}.rb`

  ```ruby
  module Cognito
    module Auth
      class {ModelToOverwrite} < ApplicationController
        include Cognito::Auth::Concerns::{ModelToOverwrite}
        attribute {new_field}, type: {new_type}, default: {new_default}

        def {method_to_extend}
          super()
          # your code
        end
  ```

  - custom attributes from aws will be accessed as `:"custom:{new_field}"`
  - in order to clean this up you can add the line `alias_attribute :"custom:{new_field}" :{new_field}`
  - since Cognito only stores strings and integers for custom attributes there is a custom attribute type included:
    - cognito_bool: converts a string stored in aws into a boolean and then back into a string in aws

+ Views
  - create a new file `views/cognito/auth/{view_to_overwrite}.rb`
  - to include a copy of the old view use `render partial: {view_to_overwrite}`

+ Assets
  - overwrite `views/layouts/cognito/auth/application.html`
  - include in the head:
   `stylesheet_link_tag 'cognito/auth/application', media: "all"`
   `javascript_include_tag 'cognito/auth/application'`
  - add a way to handle flash notices to your layout file
  - add your own stylesheets and javascript files



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
