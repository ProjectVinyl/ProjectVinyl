class CreateVideoVisits < ActiveRecord::Migration[5.1]
  def change
    create_table :video_visits do |t|
      t.integer :video_id
      t.integer :ahoy_visit_id
    end
    add_index :video_visits, :video_id
    add_index :video_visits, :ahoy_visit_id
  end
end
