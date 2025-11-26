class CreateAiConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.string :title
      t.jsonb :context_snapshot, null: false, default: {}

      t.timestamps
    end
  end
end
