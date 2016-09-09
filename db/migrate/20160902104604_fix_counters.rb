class FixCounters < ActiveRecord::Migration
  def change
    Tag.all.each do |t|
      t.video_count = VideoGenre.where(tag_id: t.id).count
      t.user_count = ArtistGenre.where(tag_id: t.id).count
      t.save
    end
  end
end
