module Cognito
  module Auth
    module Concerns
      module UserController
        extend ActiveSupport::Concern
        included do
          layout 'cognito/auth/application'
        end

        def index
            @users = Cognito::Auth::User.find_all
        end

        def new
          @user = Cognito::Auth::User.new()
        end

        def create
          @user = invite_user(params[:user][:email])
          redirect_to admin_users_edit_path(@user.username)
        end

        def edit
          @user = Cognito::Auth::User.find(params[:username])
        end

        def update
          @user = Cognito::Auth::User.find(params[:username])
          @user.update(params[:user])
          @user.save

          redirect_to admin_users_path
        end
      end
    end
  end
end
