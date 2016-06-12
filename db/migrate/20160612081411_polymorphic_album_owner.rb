class PolymorphicAlbumOwner < ActiveRecord::Migration
  def change
    add_column :albums, :owner_id, :integer
    add_column :albums, :owner_type, :string
    add_index :albums, :owner_id
    remove_column :albums, :artist_id
    
    drop_table :stars
  end
end
