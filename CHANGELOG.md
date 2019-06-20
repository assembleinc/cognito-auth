+ 0.5.9
  - track requested url when redirecting to login
  - once login is complete redirect to that url if configuration `:login_to_root` is false
  - `:login_to_root` defaults to false
+ 0.5.8
  - downcase and strip email for login, forgot_password, recover_password
  - create a separate error for `password_attempts_exceeded` (the error class is `Aws::CognitoIdentityProvider::Errors::NotAuthorizedException` same as for incorrect password)
  - recover from errors on passwords_controller create method
  
+ 0.5.5
  -  extract `after_login_success`, `handle_login_challenge` and `handle_service_error` into their own methods that can be easily overwritten

+ 0.5.4
  - Extract token verification into its own  method that is accessible to controllers as logged_in?

+ 0.5.0
  - Bug fix if access token got edited, but token expiry time hasn't passed and id token was still valid the user could get into the app with an invalid user

+ 0.4.9
  - Change the user == method to check for responds_to(username)

+ 0.4.5
  - Throw User not found exception if searching for a non-existant user

+ 0.4.4
  - Bug fix for list users/ list groups pagination. Makes asking for a page that doesn't exist return an empty array.

+ 0.4.3
  - change Cognito::Auth::Group.find_all to Cognito::Auth::Group.all(limit: nil, page: nil)
  - change Cognito::Auth::User.find_all to Cognito::Auth::User.all(limit: nil, page: nil, filter: nil)
  - add limit and page to User.groups and Group.users methods
  - Update README with Usage Data
