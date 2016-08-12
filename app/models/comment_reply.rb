class CommentReply < ActiveRecord::Base
  belongs_to :parent, class_name: "Comment"
  belongs_to :comment
end
