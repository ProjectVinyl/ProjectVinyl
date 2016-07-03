class FeaturedAlbums < ActiveRecord::Migration
  def change
    add_column :albums, :featured, :integer, default: 0
    Album.reset_column_information
    Album.update_all(featured: 0)
  end
end
