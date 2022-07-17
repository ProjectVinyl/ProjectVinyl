class CommentReply < ApplicationRecord
  belongs_to :parent, class_name: "Comment"
  belongs_to :comment

  def self.notify_recipients(receivers, comment)
    Notification.send_to(
      (receivers.uniq - [comment.user_id]),
      notification_params: {
        message: "#{comment.user.username} has <b>replied</b> to your comment on <b>#{comment.comment_thread.title}</b>",
        location: comment.link,
        originator: comment
      },
      toast_params: {
        title: "@#{comment.user.username} replied",
        params: comment.toast_params
    })
  end
end
