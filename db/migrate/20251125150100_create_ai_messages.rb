class CreateAiMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_messages do |t|
      t.references :ai_conversation, null: false, foreign_key: true
      t.integer :sender, null: false, default: 0
      t.text :content
      t.jsonb :metadata, null: false, default: {}
      t.boolean :stored_exam, null: false, default: false

      t.timestamps
    end

    add_index :ai_messages, :stored_exam
  end
end
