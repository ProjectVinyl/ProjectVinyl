class AutoSortingAlbums < ActiveRecord::Migration
  def change
    change_table(:album_items) {|t| t.timestamps }
    add_column :albums, :reverse_ordering, :boolean, default: false
    add_column :albums, :ordering, :integer, default: 0
    AlbumItem.reset_column_information
    AlbumItem.all.each do |i|
      i.created_at = i.index
      i.save
    end
  end
end
