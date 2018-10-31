# Cognito::Auth
Allows one to quickly boot up a rails application using Amazon Cognito as a login authentication service
Converts AWS struct objects returned by the aws-sdk into Active Model objects

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'cognito-auth'
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

Create a file called `config/initializers/cognito_auth.rb`
```ruby
Cognito::Auth.configure do |config|
  config.user_pool_id = Rails.application.credentials.user_pool_id
  config.client_id = Rails.application.credentials.client_id
  config.user_pool_region = Rails.application.credentials.user_pool_region
end
```

Other configuration parameters include:
- `allowed_groups`: only users part of these groups will be allowed to access to the application
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

## Core

## Routes

## Models

## Controllers

## Views

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
