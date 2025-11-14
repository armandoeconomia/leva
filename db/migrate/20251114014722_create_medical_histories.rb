class CreateMedicalHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_histories do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :doctor, null: false, foreign_key: true
      t.date :registration_date
      t.text :diagnosis
      t.text :treatment
      t.text :prescription

      t.timestamps
    end
  end
end
