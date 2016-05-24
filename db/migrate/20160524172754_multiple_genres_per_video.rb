class MultipleGenresPerVideo < ActiveRecord::Migration
  def change
    create_table :video_genres do |t|
      t.integer :video_id
      t.integer :genre_id
    end
    add_index :video_genres, :video_id
    add_index :video_genres, :genre_id
    
    remove_column :videos, :genre_id
  end
end
