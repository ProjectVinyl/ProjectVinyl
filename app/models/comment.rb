class Comment < ApplicationRecord
  include Reportable
  include Indirected
  include Statable
  include UserCachable

  belongs_to :comment_thread, touch: true

  has_many :comment_replies, dependent: :destroy
  has_many :mentions, class_name: "CommentReply", foreign_key: "comment_id"
  has_many :likes, class_name: "CommentVote", foreign_key: "comment_id"

  scope :decorated, -> { includes(:likes, :direct_user, :mentions) }
  scope :with_owner, -> { includes(comment_thread: [:owner]) }
  scope :visible, -> { joins(:comment_thread).where("comments.hidden = false AND NOT comment_threads.owner_type IN ('Report', 'Pm')") }
  scope :with_likes, ->(user) {
    if user.present?
      return joins("LEFT JOIN comment_votes ON comment_votes.comment_id = comments.id AND comment_votes.user_id = #{user.id}")
        .select('comments.*, comment_votes.user_id AS is_liked_flag')
    end
  }
  scope :of_type, ->(owner_type) { visible.where("comment_threads.owner_type = ?", owner_type) }
  scope :with_threads, ->(owner_type) { visible.includes(:direct_user, :comment_thread).of_type(owner_type) }
  scope :encode_open_id, ->(i) { i.to_s(36) }
  scope :decode_open_id, ->(s) { s.to_i(36) }

  after_save :dispatch_mentions, if: :saved_change_to_bbc_content?
  after_create :bump_thread

  def self.parse_bbc_with_replies_and_mentions(bbc, sender)
    mentions = []
    replies = []
    chapters = {}

    nodes = ProjectVinyl::Bbc::Bbcode.from_bbc(bbc)
    nodes.set_resolver do |trace, tag_name, tag, fallback|
      if tag_name == :at
        if user = User.find_for_mention(tag.inner_text)
          mentions << user.id if !trace.include?(:q) && (!sender.private_message? || sender.contributing?(user))
          next "<a class=\"user-link\" data-id=\"#{user.id}\" href=\"#{user.link}\">#{user.username}</a>"
        end
      end

      replies << Comment.decode_open_id(tag.inner_text) if tag_name == :reply && !trace.include?(:q)
      VideoChapter.read_from_node(tag){ |chapter| chapters[chapter[:timestamp]] = chapter } if tag_name == :timestamp

      fallback.call
    end

    return {
      html: nodes.outer_html,
      mentions: mentions,
      replies: replies,
      chapters: chapters.values
    }
  end

  def liked?
    (respond_to? :is_liked_flag) && is_liked_flag
  end

  def get_open_id
    oid
  end

  def oid
    Comment.encode_open_id(id)
  end

  def page(order = :id, per_page = 30, reverse = false)
    position = Comment.where("comment_thread_id = ? AND #{order} #{reverse ? '>' : '<'}= ?", comment_thread_id, send(order)).count
    (position.to_f / per_page).ceil
  end

  def upvote(user, incr)
    incr = incr.to_i
    vote = likes.where(user_id: user.id).first

    if vote.nil? && incr > 0
      vote = likes.create(user_id: user.id)
    elsif incr < 0 && !vote.nil?
      vote.destroy
    end

    self.save

    comment_thread.owner.compute_hotness if comment_thread.video?

    likes.count
  end

  def link
    "#{comment_thread.location}#comment_#{oid}"
  end

  def report(sender_id, params)
    Report.generate_report(
      reportable: self,
      user_id: sender_id
    )
  end

  def preview
    BbcodeHelper.emotify bbc_content
  end

  def toast_params
    {
      badge: '/favicon.ico',
      icon: user.avatar,
      body: preview
    }
  end

  def send_mention_notification(receivers)

    if comment_thread.video?
      message = "#{user.username} <b>mentioned</b> you in their comment on <b>#{comment_thread.title}</b>"
    else
      message = "#{user.username} <b>mentioned</b> you in <b>#{comment_thread.title}</b>"
    end

    Notification.send_to(
      (receivers.uniq - [user_id]),
      notification_params: {
        message: message,
        location: link,
        originator: self
      },
      toast_params: {
        title: "@#{user.username} mentioned you",
        params: toast_params
    })
  end

  def send_reply_notification(items)
    CommentReply.where(parent_id: id).delete_all
    items = items.uniq
    if !items.empty?
      receivers = []
      replied_to = (Comment.where('id IN (?) AND comment_thread_id = ?', items, comment_thread_id).map do |i|
        receivers << i.user_id
        "(#{i.id},#{id})"
      end).join(', ')
      if !replied_to.empty?
        CommentReply.notify_recipients(receivers, self)
        ApplicationRecord.connection.execute("INSERT INTO comment_replies (comment_id, parent_id) VALUES #{replied_to}")
      end
    end
  end

  private
  def dispatch_mentions
    bbc = Comment.parse_bbc_with_replies_and_mentions(bbc_content, comment_thread)
    send_reply_notification(bbc[:replies])
    send_mention_notification(bbc[:mentions])
  end

  def bump_thread
    comment_thread.total_comments = comment_thread.comments.count
    comment_thread.save
    comment_thread.comment_posted(self)
  end
end
