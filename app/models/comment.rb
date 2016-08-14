class Comment < ActiveRecord::Base
  REPLY_MATCHER = /(?<=\>\>)[1234567890abcdefghijklmnopqrstuvwxyz]+(?= |\s|\n|$)/
  QUOTED_TEXT = /\[q\][^\]]*\[\/q\]/
  
  belongs_to :comment_thread
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  
  has_many :comment_replies, dependent: :destroy
  has_many :mentions, class_name: "CommentReply", foreign_key: "comment_id"
  
  def self.Finder
    return Comment.includes(:direct_user, :mentions)
  end
  
  def self.get_with_replies(id)
    return Comment.Finder.where(id: id).first
  end
  
  def user
    return self.direct_user || @dummy_user || (@dummy_user = User.dummy(self.user_id))
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
      items = items | Comment.decode_open_id(match)
    end
    if items.length > 0
      recievers = []
      replied_to = (Comment.where('id IN (?) AND comment_thread_id = ?', items, self.comment_thread_id).map { |i|
        recievers << i.user_id
        '(' + i.id.to_s + ',' + self.id.to_s + ')'
      }).join(', ')
      if replied_to.length > 0
        Notification.notify_recievers(recievers, self,
             self.user.username + " has <b>replied</b> to your comment on <b>" + self.comment_thread.title + "</b>",
             self.comment_thread.location)
        ActiveRecord::Base.connection.execute('INSERT INTO comment_replies (`comment_id`,`parent_id`) VALUES ' + replied_to)
      end
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
