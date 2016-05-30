class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer :user_id
      t.integer :video_id
      t.boolean :negative
      t.timestamps null: false
    end
  end
end
