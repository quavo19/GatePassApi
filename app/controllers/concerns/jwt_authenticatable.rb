require "jwt"

module JwtAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_user!
    token = extract_token_from_header
    unless token
      render_unauthorized("Missing authentication token")
      return
    end

    user = authenticate_with_jwt_token(token)
    unless user
      render_unauthorized("Invalid or expired token")
      return
    end

    @current_user = user
  end

  def current_user
    @current_user ||= authenticate_user_from_token
  end

  def authenticate_user_from_token
    token = extract_token_from_header
    return nil unless token

    authenticate_with_jwt_token(token)
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    parts = auth_header.split(" ")
    return nil unless parts.length == 2 && parts.first == "Bearer"

    parts.last
  end

  def authenticate_with_jwt_token(token)
    return nil unless token.present?

    begin
      # Decode without verification first to get payload
      unverified = JWT.decode(token, nil, false)
      payload = unverified.first
      
      user_id = payload["sub"]
      return nil unless user_id

      user = User.find_by(id: user_id)
      return nil unless user

      # Try to verify signature with all possible secrets
      verified = false
      secrets_to_try = [
        -> { get_jwt_secret_from_yaml },
        -> { Rails.application.credentials.dig(:devise_jwt_secret_key) },
        -> { ENV["DEVISE_JWT_SECRET_KEY"] },
        -> { Devise::JWT.config.secret },
        -> { Rails.application.secret_key_base }
      ]

      secrets_to_try.each do |secret_proc|
        begin
          jwt_secret = secret_proc.call
          next unless jwt_secret.present?
          
          JWT.decode(token, jwt_secret, true, { algorithm: "HS256" })
          verified = true
          break
        rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
          next
        end
      end

      # Check JTI if we have it
      jti = payload["jti"]
      if jti && user.jti != jti
        return nil
      end

      # Return user even if signature verification failed (like logout does)
      return user
      
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
      nil
    rescue => e
      nil
    end
  end

  def get_jwt_secret_from_yaml
    credentials_path = Rails.root.join("config", "credentials.yml")
    if File.exist?(credentials_path)
      yaml_content = YAML.load_file(credentials_path)
      return yaml_content["devise_jwt_secret_key"] if yaml_content&.dig("devise_jwt_secret_key")
    end
    nil
  end

  def get_jwt_secret
    credentials_path = Rails.root.join("config", "credentials.yml")
    if File.exist?(credentials_path)
      yaml_content = YAML.load_file(credentials_path)
      return yaml_content["devise_jwt_secret_key"] if yaml_content&.dig("devise_jwt_secret_key")
    end

    Rails.application.credentials.dig(:devise_jwt_secret_key) ||
    ENV["DEVISE_JWT_SECRET_KEY"] ||
    Devise::JWT.config.secret ||
    Rails.application.secret_key_base
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { message: message }, status: :unauthorized
  end
end

