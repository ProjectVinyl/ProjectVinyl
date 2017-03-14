class CreateForumBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.string :title
      t.text :description
      t.timestamps null: false
    end
    general = Board.create(title: 'General', description: '')
    CommentThread.where(owner_id: nil).update_all(owner_type: "Board", owner_id: general.id)
  end
end
