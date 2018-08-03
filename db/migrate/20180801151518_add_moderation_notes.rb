class AddModerationNotes < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :moderation_note, :string
    add_column :comments, :moderation_note, :string
  end
end
