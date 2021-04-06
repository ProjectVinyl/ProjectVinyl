class AddTimestampToVideoVisits < ActiveRecord::Migration[5.1]
  def change
    change_table :video_visits do |t|
      t.timestamps null: false
    end
  end
end
