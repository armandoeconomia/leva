class CreateDoctors < ActiveRecord::Migration[7.1]
  def change
    create_table :doctors do |t|
      t.references :user, null: false, foreign_key: true
      t.references :medical_institute, null: false, foreign_key: true
      t.integer :speciality
      t.string :medical_registration

      t.timestamps
    end
  end
end
