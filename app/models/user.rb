class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Validations
  validates :role, inclusion: { in: %w[Admin User] }, allow_nil: true

  # Set default role to User if not provided
  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role = 'User' if role.blank?
  end
end
