class Visitor < ApplicationRecord
  belongs_to :staff_member

  # Validations
  validates :ticket_number, presence: true, uniqueness: true
  validates :full_name, presence: true
  validates :phone, presence: true, format: { with: /\A(0|\+233)\d{9}\z/, message: "must be in Ghana format (0XXXXXXXXX or +233XXXXXXXXX)" }
  validates :ghana_card_number, presence: true, format: { with: /\AGHA-\d{9}-\d\z/, message: "must be in format GHA-XXXXXXXX-X" }
  validates :staff_member_id, presence: true
  validates :purpose, presence: true, inclusion: { in: %w[Meeting Interview Delivery Maintenance Consultation Training Other] }
  validates :check_in_time, presence: true
  validates :status, presence: true, inclusion: { in: %w[checked_in checked_out] }

  # Callbacks
  before_validation :generate_ticket_number, on: :create
  before_validation :set_default_status, on: :create
  before_validation :set_check_in_time, on: :create

  private

  def generate_ticket_number
    return if ticket_number.present?

    date_str = Date.current.strftime("%Y%m%d")
    random_num = format("%05d", rand(100000))
    self.ticket_number = "VIS-#{date_str}-#{random_num}"

    # Ensure uniqueness
    while Visitor.exists?(ticket_number: self.ticket_number)
      random_num = format("%05d", rand(100000))
      self.ticket_number = "VIS-#{date_str}-#{random_num}"
    end
  end

  def set_default_status
    self.status = 'checked_in' if status.blank?
  end

  def set_check_in_time
    self.check_in_time = Time.current if check_in_time.blank?
  end
end

