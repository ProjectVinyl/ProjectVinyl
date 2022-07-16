module Duplicateable
  extend ActiveSupport::Concern

  included do
    belongs_to :duplicate, class_name: "Video", foreign_key: "duplicate_id"
  end

  def merge(user, other)
    do_unmerge

    self.duplicate_id = other.id

    AlbumItem.where(video_id: id).update_all('video_id = ' + other.id.to_s)
    Comment.where(comment_thread_id: comment_thread_id).update_all(comment_thread_id: other.comment_thread_id)
    mytags = tags.actual_ids
    tags = mytags - other.tags.actual_ids
    tags = tags.uniq

    if !tags.empty?
      other.add_tags(tags)
      drop_tags(mytags)
    end

    __send_merge_notification!(user, other)
    save
    self
  end

  def unmerge
    save if do_unmerge
  end

  protected
  def merge_message(user, other)
    "#{user.username} has merged <b>#{title}</b> into <b>#{other.title}</b>"
  end

  def do_unmerge
    if duplicate_id
      if other = Video.where(id: duplicate_id).first
        add_tags(other.tags.actual_ids)
        AlbumItem.where(video_id: other.id, o_video_id: id).update_all('video_id = o_video_id')
        Comment.where(comment_thread_id: other.comment_thread_id, o_comment_thread_id: comment_thread_id).update_all('comment_thread_id = o_comment_thread_id')
      end
      self.duplicate_id = 0
      return true
    end
    false
  end

  private
  def __send_merge_notification!(user, other)
    message = merge_message(user, other)
    Notification.send_to(
      (comment_thread.comments.pluck(:user_id) | [user_id]),
      notification_params: {
        message: message,
        location: comment_thread.location,
        originator: comment_thread
      },
      toast_params: {
        title: "#{comment_thread.title} has been merged",
        params: {
          badge: '/favicon.ico',
          icon: comment_thread.icon,
          body: message
        }
    })
  end
end
