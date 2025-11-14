class AddColumnsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :name, :string
    add_column :users, :last_name, :string
    add_column :users, :phone_number, :string
    add_column :users, :admin, :boolean
    add_column :users, :birthday, :date
    add_column :users, :address, :string
    add_column :users, :identification, :string
    add_column :users, :gender, :integer
  end
end
