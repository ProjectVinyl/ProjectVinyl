class Comment < ApplicationRecord
  include Reportable
  include Indirected
  include Statable
  include UserCachable
  
  belongs_to :comment_thread, touch: true
  
  has_many :comment_replies, dependent: :destroy
  has_many :mentions, class_name: "CommentReply", foreign_key: "comment_id"
  has_many :likes, class_name: "CommentVote", foreign_key: "comment_id"
  
  scope :decorated, -> {
    includes(:likes, :direct_user, :mentions)
  }
  scope :visible, -> {
    joins(:comment_thread).where("comments.hidden = false AND comment_threads.owner_type != 'Report' AND comment_threads.owner_type != 'Pm'")
  }
  scope :with_likes, ->(user) { 
    if !user.nil?
      return joins("LEFT JOIN comment_votes ON comment_votes.comment_id = comments.id AND comment_votes.user_id = #{user.id}")
        .select('comments.*, comment_votes.user_id AS is_liked_flag')
    end
  }
  scope :with_threads, ->(owner_type) {
    visible.includes(:direct_user, :comment_thread).where("comment_threads.owner_type = ?", owner_type)
  }
  
  def liked?
    (respond_to? :is_liked_flag) && is_liked_flag
  end
  
  scope :encode_open_id, ->(i) { i.to_s(36) }
  scope :decode_open_id, ->(s) { s.to_i(36) }
  
  def update_comment(bbc)
    self.bbc_content = bbc
    bbc = Comment.parse_bbc_with_replies_and_mentions(bbc, self.comment_thread)

    self.save
    self.send_reply_tos(bbc[:replies])
    Comment.send_mentions(bbc[:mentions], self.comment_thread, self.comment_thread.get_title, self.comment_thread.location)
    
    bbc[:html]
  end
  
  def self.parse_bbc_with_replies_and_mentions(bbc, sender)
    mentions = []
    replies = []
    nodes = ProjectVinyl::Bbc::Bbcode.from_bbc(bbc)
    nodes.set_resolver do |trace, tag_name, tag, fallback|
      if tag_name == :at
        if user = User.find_for_mention(tag.inner_text)
          if !trace.include?(:q) && (!sender.private_message? || sender.contributing?(user))
            mentions << user.id
          end
          next "<a class=\"user-link\" data-id=\"#{user.id}\" href=\"#{user.link}\">#{user.username}</a>"
        end
      end
      
      if tag_name == :reply && !trace.include?(:q)
        replies << Comment.decode_open_id(tag.inner_text)
      end
      
      fallback.call
    end
    
    return {
      html: nodes.outer_html,
      mentions: mentions,
      replies: replies
    }
  end
  
  def send_reply_tos(items)
    CommentReply.where(parent_id: self.id).delete_all
    items = items.uniq
    if !items.empty?
      receivers = []
      replied_to = (Comment.where('id IN (?) AND comment_thread_id = ?', items, self.comment_thread_id).map do |i|
        receivers << i.user_id
        "(#{i.id},#{self.id})"
      end).join(', ')
      receivers = receivers.uniq - [self.user_id]
      if !replied_to.empty?
        Notification.notify_receivers(receivers, self,
          "#{self.user.username} has <b>replied</b> to your comment on <b>#{self.comment_thread.get_title}</b>",
          self.comment_thread.location)
        ApplicationRecord.connection.execute("INSERT INTO comment_replies (comment_id, parent_id) VALUES #{replied_to}")
      end
    end
  end
  
  def self.send_mentions(receivers, sender, title, location)
    receivers = receivers.uniq - [sender.user_id]
    Notification.notify_receivers(receivers, sender, "You have been <b>mentioned</b> on <b>#{title}</b>", location)
  end
  
  def get_open_id
    Comment.encode_open_id(self.id)
  end

  def page(order = :id, per_page = 30, reverse = false)
    position = Comment.where("comment_thread_id = ? AND #{rder} #{reverse ? '>' : '<'}= ?", self.comment_thread_id, self.send(order)).count
    (position.to_f / per_page).ceil
  end
  
  def upvote(user, incr)
    incr = incr.to_i
    vote = self.likes.where(user_id: user.id).first
    if vote.nil? && incr > 0
      vote = self.likes.create(user_id: user.id)
    elsif incr < 0 && !vote.nil?
      vote.destroy
    end
    self.score = self.likes.count
    self.save
    self.score
  end
  
  def link
    "#{comment_thread.location}#comment_#{get_open_id}"
  end
  
  def icon
    user.avatar
  end
  
  def preview
    BbcodeHelper.emotify bbc_content
  end
  
  def report(sender_id, params)
    Report.generate_report(
      reportable: self,
      user_id: sender_id
    )
  end
end
