module Api
  module V1
    class StaffMembersController < ApplicationController
      before_action :authenticate_user!

      def index
        staff_members = StaffMember.all.order(:id)

        render json: {
          status: { code: 200, message: "Staff members retrieved successfully" },
          data: staff_members.map do |staff|
            {
              id: staff.id,
              name: staff.name,
              department: staff.department
            }
          end
        }, status: :ok
      rescue => e
        render json: {
          status: { code: 500, message: "An error occurred while fetching staff members" },
          error: e.message
        }, status: :internal_server_error
      end
    end
  end
end

