class CreateStaffMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :staff_members do |t|
      t.string :name
      t.string :department

      t.timestamps
    end
  end
end
