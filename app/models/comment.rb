class Comment < ApplicationRecord
  REPLY_MATCHER = /(?<=\>\>|&gt;&gt;)[1234567890abcdefghijklmnopqrstuvwxyz]+(?= |\s|\n|$)/
  MENTION_MATCHER = /(?<=@)[^\s\[\<]+(?= |\s|\s|$)/
  QUOTED_TEXT = /\[q\].*\[\/q\]?/m

  belongs_to :comment_thread
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"

  has_many :comment_replies, dependent: :destroy
  has_many :mentions, class_name: "CommentReply", foreign_key: "comment_id"
  has_many :likes, class_name: "CommentVote", foreign_key: "comment_id"

  def self.searchable
    Comment.joins(:comment_thread).where('`comments`.hidden = false AND (`comment_threads`.owner_type != "Report" AND `comment_threads`.owner_type != "Pm")')
  end

  def self.finder
    Comment.where(hidden: false).includes(:direct_user, :mentions)
  end

  def user
    self.direct_user || @dummy_user || (@dummy_user = User.dummy(self.user_id))
  end

  def update_comment(bbc)
    self.bbc_content = ApplicationHelper.demotify(bbc)
    bbc = Comment.extract_mentions(self.bbc_content, self.comment_thread, self.comment_thread.get_title, self.comment_thread.location)
    self.html_content = ApplicationHelper.emotify(bbc)
    self.extract_reply_tos(bbc)
    self.save
    self.html_content
  end

  def extract_reply_tos(bbc)
    CommentReply.where(parent_id: self.id).delete_all
    items = []
    bbc.gsub(QUOTED_TEXT, '').scan(REPLY_MATCHER) do |match|
      items << Comment.decode_open_id(match)
    end
    items = items.uniq
    if !items.empty?
      recievers = []
      replied_to = (Comment.where('id IN (?) AND comment_thread_id = ?', items, self.comment_thread_id).map do |i|
        recievers << i.user_id
        '(' + i.id.to_s + ',' + self.id.to_s + ')'
      end).join(', ')
      recievers = recievers.uniq - [self.user_id]
      if !replied_to.empty?
        Notification.notify_recievers(recievers, self,
                                      self.user.username + " has <b>replied</b> to your comment on <b>" + self.comment_thread.get_title + "</b>",
                                      self.comment_thread.location)
        ApplicationRecord.connection.execute('INSERT INTO comment_replies (`comment_id`,`parent_id`) VALUES ' + replied_to)
      end
    end
  end

  def self.extract_mentions(bbc, sender, title, location)
    recievers = []
    bbc.scan(MENTION_MATCHER) do |match|
      match_two = ApplicationHelper.url_safe(match)
      match_four = ApplicationHelper.url_safe(match.underscore)
      if sender.private_message?
        if user = User.where('LOWER(username) = ? OR LOWER(safe_name) = ? OR LOWER(safe_name) = ?', match, match_two, match_four).first
          recievers << user.id if sender.contributing?(user)
          bbc = bbc.sub('@' + match, '<a class="user-link" data-id="' + user.id.to_s + '" href="' + user.link + '">' + match + '</a>')
        end
      else
        if user = User.where('LOWER(username) = ? OR LOWER(safe_name) = ? OR LOWER(safe_name) = ?', match, match_two, match_four).first
          recievers << user.id
          bbc = bbc.sub('@' + match, '<a class="user-link" data-id="' + user.id.to_s + '" href="' + user.link + '">' + match + '</a>')
        end
      end
    end
    recievers = recievers.uniq - [sender.user_id]
    Notification.notify_recievers(recievers, sender, "You have been <b>mentioned</b> on <b>" + title + "</b>", location)
    bbc
  end

  def get_open_id
    Comment.encode_open_id(self.id)
  end

  def page(order = :id, per_page = 30, reverse = false)
    position = Comment.where('comment_thread_id = ? AND ' + order.to_s + ' ' + (reverse ? '>' : '<') + '= ?', self.comment_thread_id, self.send(order)).count
    (position.to_f / per_page).ceil
  end

  def self.encode_open_id(i)
    i.to_s(36)
  end

  def self.decode_open_id(s)
    s.to_i(36)
  end

  def is_upvoted_by(user)
    user && self.likes.where(user_id: user.id).count > 0
  end

  def upvote(user, incr)
    incr = incr.to_i
    vote = self.likes.where(user_id: user.id).first
    if vote.nil? && incr > 0
      vote = self.likes.create(user_id: user.id)
    else
      vote.destroy if incr < 0
    end
    self.score = self.likes.count
    self.save
    self.score
  end
end
