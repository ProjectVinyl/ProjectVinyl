class AddFavouritesToVideos < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :favourites, :integer
  end
end
