class CreateMedicalInstitutes < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_institutes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :address
      t.string :phone_number
      t.string :emergency_phone_number
      t.integer :institute_type
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
