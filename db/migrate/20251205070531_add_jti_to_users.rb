class AddJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :jti, :string, null: true
    add_index :users, :jti, unique: true
  end
end
