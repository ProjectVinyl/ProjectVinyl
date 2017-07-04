class CommentReply < ApplicationRecord
  belongs_to :parent, class_name: "Comment"
  belongs_to :comment
end
