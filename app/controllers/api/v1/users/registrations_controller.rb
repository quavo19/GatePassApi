module Api
  module V1
    module Users
      class RegistrationsController < Devise::RegistrationsController
        include RackSessionsFix
        respond_to :json

        def create
          build_resource(sign_up_params)

          if resource.save
            yield resource if block_given?
            if resource.active_for_authentication?
              respond_with(resource)
            else
              error_message = resource.inactive_message || "Your account is not active."
              render json: { message: error_message }, status: :unprocessable_entity
            end
          else
            clean_up_passwords resource
            set_minimum_password_length
            error_message = resource.errors.full_messages.join(", ")
            render json: { message: error_message }, status: :unprocessable_entity
          end
        rescue => e
          error_message = e.message.presence || "An error occurred during registration."
          render json: { message: error_message }, status: :unprocessable_entity
        end

        private

        def sign_up_params
          if params[:user].present?
            params.require(:user).permit(:email, :password, :password_confirmation, :name, :role)
          else
            params.permit(:email, :password, :password_confirmation, :name, :role)
          end
        end

        def respond_with(resource, _opts = {})
          render json: {
            status: { code: 200, message: "Signed up successfully." },
            data: {
              id: resource.id,
              email: resource.email,
              name: resource.name,
              role: resource.role
            }
          }, status: :ok
        end
      end
    end
  end
end
