Rails.application.routes.draw do
  mount Cognito::Auth::Engine => "/cognito-auth"
end
