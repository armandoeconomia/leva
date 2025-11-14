class CreateCalendars < ActiveRecord::Migration[7.1]
  def change
    create_table :calendars do |t|
      t.references :doctor, null: false, foreign_key: true
      t.date :date

      t.timestamps
    end
  end
end
