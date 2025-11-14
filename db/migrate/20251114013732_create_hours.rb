class CreateHours < ActiveRecord::Migration[7.1]
  def change
    create_table :hours do |t|
      t.references :calendar, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end
