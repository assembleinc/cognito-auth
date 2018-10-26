Cognito::Auth::Engine.routes.draw do
  root to: 'session#new'
  get  '/login', to: "session#new"
  post '/login', to: "session#create"
  get  '/new-password-required', to: "session#edit_password"
  post '/new-password-required', to: "session#update_password"
  post '/logout', to: "session#destroy"


  get  '/forgot-password', to: "password#new"
  post '/forgot-password', to: "password#create"
  get  '/recover-password', to: "password#edit"
  post '/recover-password', to: "password#update"
  #
  # get  '/profile', to: "profile#edit"
  # post '/profile', to: "profile#update"
  # post '/profile/change-password', to: "profile#update_password"
  # post '/profile/send-attribute-verification', to: "profile#send_attribute_verification"
  # post '/profile/verify_attribute', to: "profile#verify_attribute"
end
