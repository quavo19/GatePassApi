class CreateVisitors < ActiveRecord::Migration[8.0]
  def change
    create_table :visitors do |t|
      t.string :ticket_number, null: false
      t.string :full_name, null: false
      t.string :phone, null: false
      t.string :ghana_card_number, null: false
      t.integer :staff_member_id, null: false
      t.string :purpose, null: false
      t.datetime :check_in_time, null: false
      t.datetime :check_out_time
      t.string :status, default: 'checked_in', null: false

      t.timestamps
    end

    add_index :visitors, :ticket_number, unique: true
    add_index :visitors, :staff_member_id
    add_foreign_key :visitors, :staff_members, column: :staff_member_id
  end
end
