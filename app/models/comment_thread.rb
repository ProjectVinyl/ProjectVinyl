class CommentThread < ActiveRecord::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  
  belongs_to :owner, polymorphic: true
  
  def get_comments
    return comments.includes(:direct_user, :mentions)
  end
  
  def location
    if self.owner_type == 'Video'
      return '/view/' + self.owner_id.to_s
    end
    if self.owner_type == 'Report'
      return '/admin/report/view/' + self.owner_id.to_s
    end
    return '/thread/' + self.id.to_s
  end
end
