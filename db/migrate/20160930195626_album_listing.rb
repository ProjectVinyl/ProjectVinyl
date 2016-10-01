class AlbumListing < ActiveRecord::Migration
  def change
    add_column :albums, :listing, :integer, default: 0
    Album.update_all('listing = 0')
  end
end
