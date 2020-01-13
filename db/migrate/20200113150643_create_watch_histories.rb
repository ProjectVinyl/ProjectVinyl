class CreateWatchHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :watch_histories do |t|
      t.integer :user_id
      t.integer :video_id
      t.integer :watch_time
      t.timestamps null: false
    end
  end
end
