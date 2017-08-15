class TagHistory < ApplicationRecord
  belongs_to :tag
  belongs_to :video
  belongs_to :user

  def self.destroy_for(video)
    TagHistory.where(video_id: video.id).destroy_all
  end
  
  def self.record_tag_changes(added_tags, removed_tags, video_id, user_id = 0)
    entries = []
    added_tags.each do |i|
      entries << { tag_id: i, video_id: video_id, user_id: user_id, added: true }
    end
    removed_tags.each do |i|
      entries << { tag_id: i, video_id: video_id, user_id: user_id, added: false }
    end
    TagHistory.create(entries)
  end
  
  def self.record_source_changes(video, user_id = 0)
    TagHistory.create(user_id: user_id, video_id: video.id, added: nil, value: video.source)
  end

  def action
    self.added ? 'Added' : self.added.nil? ? 'Source Change' : 'Removed'
  end

  def action_class
    self.added ? 'added' : self.added.nil? ? 'altered' : 'removed'
  end
end
