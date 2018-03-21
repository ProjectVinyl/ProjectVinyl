class AlbumsSafeTitles < ActiveRecord::Migration
  def change
    add_column :albums, :safe_title, :string
    Album.reset_column_information
    Album.all.each do |i|
      i.safe_title = PathHelper.url_safe(i.title)
      i.save
    end
  end
end
