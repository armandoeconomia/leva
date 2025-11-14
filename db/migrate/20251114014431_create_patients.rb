class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :blood_type
      t.string :emergency_contact
      t.string :allergies
      t.text :medical_history
      t.text :pathology
      t.string :medical_insurance
      t.integer :marital_status
      t.float :payments

      t.timestamps
    end
  end
end
