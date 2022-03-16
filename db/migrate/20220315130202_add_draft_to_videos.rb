class AddDraftToVideos < ActiveRecord::Migration[5.1]
  def change
    add_column :videos, :draft, :boolean, default: true
    Video.reset_column_information
    Video.update_all(draft: false)
  end
end
