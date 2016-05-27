class AddscoreTovideo < ActiveRecord::Migration
  def change
    add_column :videos, :score, :integer, default: 0
  end
  
  def up
    change_column :artists, :description, :text, default: "no description provided"
    change_column :artists, :bio, :text, default: ""

    change_column :videos, :audio_only, :boolean, default: false
    change_column :videos, :upvotes, :integer, default: 0
    change_column :videos, :downvotes, :integer, default: 0
    change_column :videos, :length, :integer, default: 0
    change_column :videos, :description, :text, default: "no description provided"
    
    Video.find_each do |video|
      video.getComputedScore()
    end
  end
end
