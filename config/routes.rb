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

end
