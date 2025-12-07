require "jwt"

module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        include RackSessionsFix
        include Devise::Controllers::Helpers
        include JwtAuthenticatable
        respond_to :json

        # Skip verify_signed_out_user filter for JWT authentication
        # This filter checks for session-based auth which doesn't work with JWT
        skip_before_action :verify_signed_out_user, only: :destroy

        def create
          email = params[:user]&.dig(:email) || params[:email]
          password = params[:user]&.dig(:password) || params[:password]

          user = User.find_by(email: email)

          if user && user.valid_password?(password)
            sign_in(user)

            jwt_token = request.env["warden-jwt_auth.token"]

            if jwt_token.blank?
              jwt_token = generate_jwt_token_for_user(user)
            end

            respond_with(user, jwt_token)
          else
            render json: {
              status: { code: 401, message: "Invalid email or password." }
            }, status: :unauthorized
          end
        rescue
          render json: {
            status: { code: 500, message: "An error occurred during login." }
          }, status: :internal_server_error
        end

        private

        def respond_with(current_user, jwt_token = nil, _opts = {})
          if jwt_token.present?
            response.headers["Authorization"] = "Bearer #{jwt_token}"
          end

          render json: {
            status: { code: 200, message: "Logged in successfully." },
            data: {
              id: current_user.id,
              email: current_user.email,
              name: current_user.name,
              role: current_user.role
            }
          }, status: :ok
        end

        def generate_jwt_token_for_user(user)
          # Use the get_jwt_secret from JwtAuthenticatable to ensure consistency
          jwt_secret = get_jwt_secret

          payload = {
            sub: user.id.to_s,
            scp: "api_v1_user",
            aud: nil,
            iat: Time.now.to_i,
            exp: (Time.now + 30.minutes).to_i,
            jti: user.jti
          }

          JWT.encode(payload, jwt_secret, "HS256")
        end

        def respond_to_on_destroy
          authenticated_user = authenticate_user_from_token

          if authenticated_user
            render json: {
              status: 200,
              message: "Logged out successfully."
            }, status: :ok
          else
            render json: { message: "Couldn't find an active session." }, status: :unauthorized
          end
        end
      end
    end
  end
end
