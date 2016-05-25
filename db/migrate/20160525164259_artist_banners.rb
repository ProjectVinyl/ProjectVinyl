class ArtistBanners < ActiveRecord::Migration
  def change
    add_column :artists, :banner_set, :boolean
  end
end
