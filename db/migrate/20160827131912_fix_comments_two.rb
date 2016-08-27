class FixCommentsTwo < ActiveRecord::Migration
  def change
    Comment.update_all('hidden = false')
  end
end
