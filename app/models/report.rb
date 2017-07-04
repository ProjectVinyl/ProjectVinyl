class Report < ApplicationRecord
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  belongs_to :video

  has_one :comment_thread, as: :owner, dependent: :destroy

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end

  def write(msg)
    self.other << "<br>#{msg}"
  end
end
