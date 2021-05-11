class AddViewsToAlbums < ActiveRecord::Migration[5.1]
  def change
    add_column :albums, :views, :integer, default: 0
  end
end
