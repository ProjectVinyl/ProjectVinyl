class Comment < ActiveRecord::Base
  REPLY_MATCHER = /(?<=\>\>)[1234567890abcdefghijklmnopqrstuvwxyz]+(?= |\s|\n|$)/
  QUOTED_TEXT = /\[q\][^\]]*\[\/q\]/
  
  belongs_to :video
  belongs_to :user
  has_one :artist, :through => :user
  
  has_many :mentions, class_name: "CommentReply", foreign_key: "comment_id"
  
  def self.Finder
    return Comment.includes(:user, :artist, :mentions)
  end
  
  def self.get_with_replies(id)
    return Comment.Finder.where(id: id).first
  end
  
  def self.pull_thread(thread_id)
    return Comment.Finder.where(video_id: thread_id).order(:created_at).reverse_order
  end
  
  def self.thread_exists?(thread_id)
    return !Video.where(id: thread_id).first.nil?
  end
  
  def update_comment(bbc)
    self.bbc_content = ApplicationHelper.demotify(bbc)
    self.html_content = ApplicationHelper.emotify(self.bbc_content)
    self.extract_reply_tos(bbc)
    self.save
    return self.html_content
  end
  
  def extract_reply_tos(bbc)
    CommentReply.where(parent_id: self.id).delete_all
    items = []
    bbc.gsub(QUOTED_TEXT,'').scan(REPLY_MATCHER) do |match|
      items << Comment.decode_open_id(match)
    end
    message = self.user.username + " has <b>replied</b> to your comment on <b>" + self.video.title + "</b>"
    source = "/view/" + self.video_id.to_s
    replied_to = (Comment.where('id IN (?) AND video_id = ?', items, self.video_id).map { |i|
      i.user.send_notification(message, source)
      '(' + i.id.to_s + ',' + self.id.to_s + ')'
    }).join(', ')
    if replied_to.length > 0
      ActiveRecord::Base.connection.execute('INSERT INTO comment_replies (`comment_id`,`parent_id`) VALUES ' + replied_to)
    end
  end
  
  def get_open_id
    return Comment.encode_open_id(self.id)
  end
  
  def self.encode_open_id(i)
    return i.to_s(36)
  end
  
  def self.decode_open_id(s)
    return s.to_i(36)
  end
end
