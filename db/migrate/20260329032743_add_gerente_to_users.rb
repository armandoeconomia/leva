class AddGerenteToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :gerente, :boolean, default: false
  end
end
