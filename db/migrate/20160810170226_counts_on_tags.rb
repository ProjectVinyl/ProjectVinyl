class CountsOnTags < ActiveRecord::Migration
  def change
    add_column :tags, :video_count, :integer, default: 0
    add_column :tags, :user_count, :integer, default: 0
    Tag.reset_column_information
    Tag.all.each do |t|
      t.video_count = t.videos.pluck(:id).uniq.length
      t.user_count = t.users.pluck(:id).uniq.length
      t.save
    end
  end
end
