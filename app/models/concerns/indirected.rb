module Indirected
  extend ActiveSupport::Concern
	
  included do
    belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  end
  
  def report(sender_id, params)
		
  end
  
  def user
    if self.user_id < 0 
      return @dummy || (@dummy = User.dummy(self.user_id))
    end
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end
end
