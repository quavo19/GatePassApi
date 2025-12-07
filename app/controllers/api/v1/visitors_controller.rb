module Api
  module V1
    class VisitorsController < ApplicationController
      before_action :authenticate_user!

      def check_in
        visitor_params = check_in_params
        return if performed? # Return early if error response was already rendered
        return unless visitor_params # Return if params validation failed

        # Validate staff member exists
        staff_member = StaffMember.find_by(id: visitor_params[:staffMemberId])
        unless staff_member
          render json: {
            status: { code: 400, message: "Staff member not found" }
          }, status: :bad_request
          return
        end

        # Create visitor
        visitor = Visitor.new(
          full_name: visitor_params[:fullName],
          phone: visitor_params[:phone],
          ghana_card_number: visitor_params[:ghanaCardNumber],
          staff_member_id: visitor_params[:staffMemberId],
          purpose: visitor_params[:purpose]
        )

        if visitor.save
          render json: {
            status: { code: 200, message: "Check-in successful" },
            data: {
              ticketNumber: visitor.ticket_number,
              visitor: {
                fullName: visitor.full_name,
                phone: visitor.phone,
                ghanaCardNumber: visitor.ghana_card_number,
                staffMember: "#{staff_member.name} - #{staff_member.department}",
                purpose: visitor.purpose,
                checkInTime: visitor.check_in_time.iso8601,
                status: visitor.status
              }
            }
          }, status: :ok
        else
          render json: {
            status: { code: 400, message: "Validation failed" },
            errors: visitor.errors.full_messages
          }, status: :bad_request
        end
      rescue => e
        render json: {
          status: { code: 500, message: "An error occurred during check-in" },
          error: e.message
        }, status: :internal_server_error
      end

      def index
        # Build query with optional ticketNumber search
        visitors = Visitor.includes(:staff_member)
                         .order(check_in_time: :desc)

        # Filter by ticketNumber if provided
        if params[:ticketNumber].present?
          visitors = visitors.where("ticket_number ILIKE ?", "%#{params[:ticketNumber]}%")
        end

        # Paginate using kaminari
        page = params[:page].to_i
        page = 1 if page < 1
        
        # Use kaminari pagination
        paginated_visitors = visitors.page(page).per(10)

        data = paginated_visitors.map do |visitor|
          staff_member = visitor.staff_member
          {
            id: visitor.id.to_s,
            fullName: visitor.full_name,
            phone: visitor.phone,
            staffMember: staff_member ? "#{staff_member.name} - #{staff_member.department}" : "Unknown - Unknown",
            purpose: visitor.purpose,
            ticketNumber: visitor.ticket_number,
            checkInTime: visitor.check_in_time.iso8601,
            status: visitor.status
          }
        end

        render json: {
          status: { code: 200, message: "Success" },
          data: data,
          pagination: {
            currentPage: paginated_visitors.current_page,
            totalPages: paginated_visitors.total_pages,
            totalCount: paginated_visitors.total_count,
            perPage: paginated_visitors.limit_value
          }
        }, status: :ok
      rescue => e
        Rails.logger.error "Error in visitors#index: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: {
          status: { code: 500, message: "An error occurred while fetching visitors" },
          error: e.message.to_s
        }, status: :internal_server_error
      end

      def checkout
        ticket_number = params[:ticketNumber]

        unless ticket_number.present?
          render json: {
            status: { code: 400, message: "ticketNumber is required" }
          }, status: :bad_request
          return
        end

        visitor = Visitor.includes(:staff_member).find_by(ticket_number: ticket_number)

        unless visitor
          render json: {
            status: { code: 404, message: "Visitor with ticket number #{ticket_number} not found" }
          }, status: :not_found
          return
        end

        if visitor.status == 'checked_out'
          render json: {
            status: { code: 400, message: "Visitor has already checked out" }
          }, status: :bad_request
          return
        end

        visitor.status = 'checked_out'
        visitor.check_out_time = Time.current

        if visitor.save
          staff_member = visitor.staff_member
          render json: {
            status: { code: 200, message: "Check-out successful" },
            data: {
              ticketNumber: visitor.ticket_number,
              visitor: {
                fullName: visitor.full_name,
                phone: visitor.phone,
                ghanaCardNumber: visitor.ghana_card_number,
                staffMember: staff_member ? "#{staff_member.name} - #{staff_member.department}" : "Unknown - Unknown",
                purpose: visitor.purpose,
                checkInTime: visitor.check_in_time.iso8601,
                checkOutTime: visitor.check_out_time.iso8601,
                status: visitor.status
              }
            }
          }, status: :ok
        else
          render json: {
            status: { code: 400, message: "Validation failed" },
            errors: visitor.errors.full_messages
          }, status: :bad_request
        end
      rescue => e
        render json: {
          status: { code: 500, message: "An error occurred during check-out" },
          error: e.message
        }, status: :internal_server_error
      end

      def latest_check_ins
        limit = validate_limit(params[:limit])
        return if performed? # Return early if error response was already rendered
        return unless limit # Return if limit validation failed

        visitors = Visitor.includes(:staff_member)
                         .where(status: 'checked_in')
                         .order(check_in_time: :desc)
                         .limit(limit)

        data = visitors.map do |visitor|
          {
            id: visitor.id.to_s,
            fullName: visitor.full_name,
            phone: visitor.phone,
            staffMember: "#{visitor.staff_member.name} - #{visitor.staff_member.department}",
            purpose: visitor.purpose,
            ticketNumber: visitor.ticket_number,
            checkInTime: visitor.check_in_time.iso8601,
            status: visitor.status
          }
        end

        render json: {
          status: { code: 200, message: "Success" },
          data: data
        }, status: :ok
      rescue => e
        render json: {
          status: { code: 500, message: "An error occurred while fetching check-ins" },
          error: e.message
        }, status: :internal_server_error
      end

      def latest_check_outs
        limit = validate_limit(params[:limit])
        return if performed? # Return early if error response was already rendered
        return unless limit # Return if limit validation failed

        visitors = Visitor.includes(:staff_member)
                         .where(status: 'checked_out')
                         .order(check_out_time: :desc)
                         .limit(limit)

        data = visitors.map do |visitor|
          {
            id: visitor.id.to_s,
            fullName: visitor.full_name,
            phone: visitor.phone,
            staffMember: "#{visitor.staff_member.name} - #{visitor.staff_member.department}",
            purpose: visitor.purpose,
            ticketNumber: visitor.ticket_number,
            checkInTime: visitor.check_in_time.iso8601,
            checkOutTime: visitor.check_out_time&.iso8601,
            status: visitor.status
          }
        end

        render json: {
          status: { code: 200, message: "Success" },
          data: data
        }, status: :ok
      rescue => e
        render json: {
          status: { code: 500, message: "An error occurred while fetching check-outs" },
          error: e.message
        }, status: :internal_server_error
      end

      def logs
        # Build query
        visitors = Visitor.includes(:staff_member)
                         .order(check_in_time: :desc)

        # Filter by ticketNumber if provided
        if params[:ticketNumber].present?
          visitors = visitors.where("ticket_number ILIKE ?", "%#{params[:ticketNumber]}%")
        end

        # Filter by time period
        time_period = params[:timePeriod]
        if time_period.present?
          case time_period.downcase
          when 'today'
            start_date = Date.current.beginning_of_day
            end_date = Date.current.end_of_day
          when 'thisweek'
            start_date = Date.current.beginning_of_week
            end_date = Date.current.end_of_week
          when 'thismonth'
            start_date = Date.current.beginning_of_month
            end_date = Date.current.end_of_month
          when 'thisyear'
            start_date = Date.current.beginning_of_year
            end_date = Date.current.end_of_year
          else
            render json: {
              status: { code: 400, message: "Invalid timePeriod. Valid values: today, thisweek, thismonth, thisyear" }
            }, status: :bad_request
            return
          end

          visitors = visitors.where("check_in_time >= ? AND check_in_time <= ?", start_date, end_date)
        end

        # Paginate using kaminari
        page = params[:page].to_i
        page = 1 if page < 1
        paginated_visitors = visitors.page(page).per(10)

        data = paginated_visitors.map do |visitor|
          staff_member = visitor.staff_member
          {
            id: visitor.id.to_s,
            fullName: visitor.full_name,
            phone: visitor.phone,
            ghanaCardNumber: visitor.ghana_card_number,
            staffMember: staff_member ? "#{staff_member.name} - #{staff_member.department}" : "Unknown - Unknown",
            purpose: visitor.purpose,
            ticketNumber: visitor.ticket_number,
            checkInTime: visitor.check_in_time.iso8601,
            checkOutTime: visitor.check_out_time&.iso8601,
            status: visitor.status
          }
        end

        render json: {
          status: { code: 200, message: "Success" },
          data: data,
          pagination: {
            currentPage: paginated_visitors.current_page,
            totalPages: paginated_visitors.total_pages,
            totalCount: paginated_visitors.total_count,
            perPage: paginated_visitors.limit_value
          }
        }, status: :ok
      rescue => e
        Rails.logger.error "Error in visitors#logs: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: {
          status: { code: 500, message: "An error occurred while fetching logs" },
          error: e.message.to_s
        }, status: :internal_server_error
      end

      def analytics
        # 1. Department visits (Bar Chart) - Top 5
        department_visits = Visitor.joins(:staff_member)
                                   .group('staff_members.department')
                                   .count
                                   .map { |dept, count| { department: dept, count: count } }
                                   .sort_by { |item| -item[:count] }
                                   .first(5)

        # 2. Monthly visits (Line Graph) - from November last year to current month
        current_date = Date.current
        start_year = current_date.year - 1
        start_month = 11 # November
        
        monthly_visits = []
        year = start_year
        month = start_month
        
        loop do
          month_start = Date.new(year, month, 1)
          month_end = month_start.end_of_month
          
          count = Visitor.where("check_in_time >= ? AND check_in_time <= ?", month_start.beginning_of_day, month_end.end_of_day).count
          monthly_visits << {
            month: month_start.strftime("%Y-%m"),
            monthName: month_start.strftime("%B %Y"),
            count: count
          }
          
          # Move to next month
          month += 1
          if month > 12
            month = 1
            year += 1
          end
          
          # Stop if we've reached current month
          break if year > current_date.year || (year == current_date.year && month > current_date.month)
        end

        # 3. Most visited staff members (Top 5)
        most_visited_staff = Visitor.joins(:staff_member)
                                   .group('staff_members.id', 'staff_members.name', 'staff_members.department')
                                   .count
                                   .map { |(id, name, dept), count| 
                                     { 
                                       id: id, 
                                       name: name, 
                                       department: dept,
                                       visitCount: count 
                                     } 
                                   }
                                   .sort_by { |item| -item[:visitCount] }
                                   .first(5)

        # 4. Most frequent visitors (guests) - Top 5
        most_frequent_visitors = Visitor.group(:full_name, :phone)
                                       .count
                                       .map { |(name, phone), count|
                                         {
                                           fullName: name,
                                           phone: phone,
                                           visitCount: count
                                         }
                                       }
                                       .sort_by { |item| -item[:visitCount] }
                                       .first(5)

        render json: {
          status: { code: 200, message: "Success" },
          data: {
            departmentVisits: department_visits,
            monthlyVisits: monthly_visits,
            mostVisitedStaff: most_visited_staff,
            mostFrequentVisitors: most_frequent_visitors
          }
        }, status: :ok
      rescue => e
        Rails.logger.error "Error in visitors#analytics: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: {
          status: { code: 500, message: "An error occurred while fetching analytics" },
          error: e.message.to_s
        }, status: :internal_server_error
      end

      private

      def check_in_params
        params.require(:fullName)
        params.require(:phone)
        params.require(:ghanaCardNumber)
        params.require(:staffMemberId)
        params.require(:purpose)

        {
          fullName: params[:fullName],
          phone: params[:phone],
          ghanaCardNumber: params[:ghanaCardNumber],
          staffMemberId: params[:staffMemberId].to_i,
          purpose: params[:purpose]
        }
      rescue ActionController::ParameterMissing => e
        render json: {
          status: { code: 400, message: "Missing required parameter: #{e.param}" }
        }, status: :bad_request
        nil
      end

      def validate_limit(limit_param)
        # Default to 5 if not provided
        return 5 if limit_param.blank?

        # Check if it's a valid integer
        unless limit_param.to_s.match?(/^\d+$/)
          render json: {
            status: { code: 400, message: "Limit must be a valid number" }
          }, status: :bad_request
          return nil
        end

        limit = limit_param.to_i

        # Validate limit is within range
        if limit < 1
          render json: {
            status: { code: 400, message: "Limit must be at least 1" }
          }, status: :bad_request
          return nil
        end

        if limit > 10
          render json: {
            status: { code: 400, message: "Limit cannot exceed 10" }
          }, status: :bad_request
          return nil
        end

        limit
      end
    end
  end
end

