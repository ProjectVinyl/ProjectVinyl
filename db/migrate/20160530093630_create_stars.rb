class CreateStars < ActiveRecord::Migration
  def change
    create_table :stars do |t|
      t.integer :user_id
      t.integer :video_id
      
      t.timestamps null: false
    end
    remove_column :users, :album_id
  end
end
