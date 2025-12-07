# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed Staff Members
staff_members_data = [
  { name: 'John Doe', department: 'Engineering' },
  { name: 'Jane Smith', department: 'Marketing' },
  { name: 'Michael Johnson', department: 'Sales' },
  { name: 'Sarah Williams', department: 'HR' },
  { name: 'David Brown', department: 'Finance' },
  { name: 'Emily Davis', department: 'Operations' },
  { name: 'Robert Wilson', department: 'IT' },
  { name: 'Lisa Anderson', department: 'Customer Service' }
]

staff_members_data.each do |staff_data|
  StaffMember.find_or_create_by!(name: staff_data[:name]) do |staff|
    staff.department = staff_data[:department]
  end
end

puts "Seeded #{staff_members_data.count} staff members"
