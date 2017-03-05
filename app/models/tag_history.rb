class TagHistory < ActiveRecord::Base
  belongs_to :tag
  belongs_to :video
  belongs_to :user
  
  def self.destroy_for(video)
    TagHistory.where(video_id: video.id).destroy_all
  end
  
  def self.record_changes(user, video, added_tags, removed_tags)
    user = user.id
    video = video.id
    entries = added_tags.map do |i|
      {tag_id: i, video_id: video, user_id: user, added: true}
    end
    entries |= removed_tags.map do |i|
      {tag_id: i, video_id: video, user_id: user, added: false}
    end
    TagHistory.create(entries)
  end
  
  def self.record_source_change(user, video, neu)
    user = user.id
    video = video.id
    TagHistory.create(user_id: user, video_id: video, added: nil, value: neu)
  end
  
  def action
    self.added ? 'Added' : self.added.nil? ? 'Source Change' : 'Removed'
  end
  
  def action_class
    self.added ? 'added' : self.added.nil? ? 'altered' : 'removed'
  end
end
