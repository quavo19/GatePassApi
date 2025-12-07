class StaffMember < ApplicationRecord
  has_many :visitors, dependent: :destroy

  validates :name, presence: true
  validates :department, presence: true
end

