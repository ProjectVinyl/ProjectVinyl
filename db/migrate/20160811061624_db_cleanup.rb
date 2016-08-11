class DbCleanup < ActiveRecord::Migration
  def change
    remove_column :albums, :owner_type
    remove_column :artist_genres, :artist_id
    drop_table :artists
    remove_column :users, :artist_id
    remove_column :videos, :artist_id
    drop_table :genres
    remove_column :comments, :parent_id
    rename_column :albums, :owner_id, :user_id
  end
end
