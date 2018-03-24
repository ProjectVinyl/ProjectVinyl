class ApiToken < ApplicationRecord
  has_one :user
  
  has_secure_token
  
  def self.get_token(user)
    token = ApiToken.where(user_id: user.id).first
    if !token
      return ApiToken.create(user: user)
    end
    
    token
  end
  
  def self.validate_token(key)
    token = ApiToken.includes(:user).where(token: key).first
    if token && token.user && !token.user.banned 
      return token
    end
    
    nil
  end
  
  def max_hits
    50
  end
  
  def reset_interval
    1.hour
  end
  
  def hit
    if Time.zone.now > self.reset_at + reset_interval
      self.reset_at = Time.zone.now
      self.hits = 0
    end
    
    self.hits++
    self.save
    
    return self.hits <= max_hits
  end
end
