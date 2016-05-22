class AddUpvotesToVideos < ActiveRecord::Migration
  def change
    add_column :videos, :upvotes, :integer
    add_column :videos, :downvotes, :integer
  end
end
