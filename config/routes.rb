Cognito::Auth::Engine.routes.draw do
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

  # get  '/profile', to: "profile#edit"
  # post '/profile', to: "profile#update"
  # post '/profile/send-attribute-verification', to: "profile#send_attribute_verification"
  # post '/profile/verify_attribute', to: "profile#verify_attribute"
  #
  # get  '/admin/users', to: "user#index"
  # get  '/admin/users/new', to: "user#new"
  # post '/admin/users/new', to: "user#create"
  # get  '/admin/users/edit/:username', to: "user#edit", as: "admin_users_edit"
  # post  '/admin/users/edit/:username', to: "user#update"
  # delete '/admin/users/remove/:username', to: "user#remove", as: "admin_users_remove"
end
