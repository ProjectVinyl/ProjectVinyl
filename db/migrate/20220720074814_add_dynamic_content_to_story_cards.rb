class AddDynamicContentToStoryCards < ActiveRecord::Migration[5.1]
  def change
    change_table :story_cards do |t|
      t.references :content, polymorphic: true, index: true
    end
  end
end
