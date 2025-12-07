module Api
  module V1
    module Users
      class UsersController < ApplicationController
        before_action :authenticate_user!

        def show
          render json: {
            status: { code: 200, message: "User retrieved successfully." },
            data: {
              id: current_user.id,
              email: current_user.email,
              name: current_user.name,
              role: current_user.role
            }
          }, status: :ok
        end
      end
    end
  end
end
