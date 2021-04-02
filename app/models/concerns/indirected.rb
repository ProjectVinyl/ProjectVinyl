module Indirected
  extend ActiveSupport::Concern
	
  included do
    belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  end
  
  def anonymous?
    user_id.to_i <= 0 || __forced_anonymous?
  end
  
  def user
    if anonymous?
      return @dummy || (@dummy = User.dummy(__anonymous_id))
    end

    self.direct_user || @dummy || (@dummy = User.dummy(__anonymous_id))
  end

  def user=(user)
    self.direct_user = user
  end
  
  def owned_by(user)
    user && (self.user_id == user.id || user.is_contributor?)
  end
  
  def owned_by!(user)
    user && (self.user_id == user.id)
  end
  
  private
  def __forced_anonymous?
    (respond_to?(:anonymous_id) && anonymous_id.to_i != 0)
  end
  
  def __anonymous_id
    __forced_anonymous? ? anonymous_id : self.user_id.to_i
  end
end
