class CreateApiTokens < ActiveRecord::Migration[5.1]
  def change
    create_table :api_tokens do |t|
      t.integer :user_id
      t.string :token
      t.integer :hits, default: 0
      t.datetime :reset_at
      t.timestamps null: false
    end
    add_index :api_tokens, :token, unique: true
  end
end
