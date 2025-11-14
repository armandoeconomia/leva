class CreateAppointments < ActiveRecord::Migration[7.1]
  def change
    create_table :appointments do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :doctor, null: false, foreign_key: true
      t.date :date
      t.time :hour
      t.text :reason_for_consultation
      t.integer :status

      t.timestamps
    end
  end
end
