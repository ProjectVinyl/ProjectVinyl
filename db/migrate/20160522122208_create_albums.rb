class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
      t.integer :artist_id
      t.string :title
      t.text :description
      t.integer :artist_id

      t.timestamps null: false
    end
    add_index :albums, :artist_id
    
    create_table :album_items do |t|
      t.integer :album_id
      t.integer :video_id
      t.integer :index
    end
    add_index :album_items, :album_id
    add_index :album_items, :video_id
  end
end
