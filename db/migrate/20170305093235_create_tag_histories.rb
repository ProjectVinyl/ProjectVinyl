class CreateTagHistories < ActiveRecord::Migration
  def change
    create_table :tag_histories do |t|
      t.integer :video_id
      t.integer :tag_id
      t.integer :user_id
      t.boolean :added
      t.string :value
      t.timestamps null: false
    end
    
    Video.where('NOT source IS NULL AND NOT TRIM(source) = ""').each do |v|
      TagHistory.create(video_id: v.id, created_at: v.created_at, added: nil, user_id: v.user_id, value: v.source)
    end
  end
end
