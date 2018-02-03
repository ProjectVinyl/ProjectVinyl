module Roleable
  ROLE_INDICES = {
    admin: 3,
    contributor: 2,
    staff: 1,
    banned: -1
  }.freeze
  
  def self.role_for(name)
    ROLE_INDICES[name.to_sym] || 0
  end
  
  def admin?
    self.is_admin?
  end
  
  def contributor?
    self.role == 2
  end
  
  def staff?
    self.role == 1
  end
  
  def normal?
    self.role == 0
  end
  
  def banned?
    self.role < 0
  end
  
  def is_admin?
    self.role > 2
  end
  
  def is_contributor?
    self.role > 1
  end
  
  def is_staff?
    self.role > 0
  end
end
