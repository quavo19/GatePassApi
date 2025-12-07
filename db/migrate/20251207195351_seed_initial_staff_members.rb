# db/migrate/20251207_seed_initial_staff_members.rb
class SeedInitialStaffMembers < ActiveRecord::Migration[8.0]
  def up
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
  end

  def down
    # Optional: remove these staff members if rolling back
    names = [
      'John Doe', 'Jane Smith', 'Michael Johnson', 'Sarah Williams',
      'David Brown', 'Emily Davis', 'Robert Wilson', 'Lisa Anderson'
    ]
    StaffMember.where(name: names).destroy_all
  end
end
