module Roleable
  def self.role_for(name)
    if name == 'admin'
      return 3
    elsif name == 'contributor'
      return 2
    elsif name == 'staff'
      return 1
    elsif name == 'banned'
      return -1
    end
    0
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