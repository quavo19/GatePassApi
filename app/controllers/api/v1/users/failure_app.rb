module Api
  module V1
    module Users
      class FailureApp < Devise::FailureApp
        def respond
          json_error_response
        end

        def json_error_response
          self.status = 401
          self.content_type = 'application/json'
          self.response_body = { message: "User not authenticated." }.to_json
        end
      end
    end
  end
end

