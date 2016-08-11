class FixStars < ActiveRecord::Migration
  def change
    add_column :users, :star_id, :integer
    User.reset_column_information
    User.all.each do |i|
      if star = Album.where(owner_id: i.id, owner_type: "User").first
        i.star_id = star.id
        i.save
      end
    end
  end
end
