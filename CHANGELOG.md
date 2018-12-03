+ 0.4.3
  - change Cognito::Auth::Group.find_all to Cognito::Auth::Group.all(limit: nil, page: nil)
  - change Cognito::Auth::User.find_all to Cognito::Auth::User.all(limit: nil, page: nil, filter: nil)
  - add limit and page to User.groups and Group.users methods
  - Update README with Usage Data

+ 0.4.4
  - Bug fix for list users/ list groups pagination. Makes asking for a page that doesn't exist return an empty array. 
