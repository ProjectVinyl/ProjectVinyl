class CreateGenres < ActiveRecord::Migration
  def change
    create_table :genres do |t|
      t.string :name
    end
    
    add_column :videos, :length, :integer
    add_column :videos, :genre_id, :integer
    add_index :videos, :genre_id
    
    create_table :artist_genres do |t|
      t.integer :artist_id
      t.integer :genre_id
    end
    add_index :artist_genres, :artist_id
    add_index :artist_genres, :genre_id
  end
end
