class ApiToken < ApplicationRecord
  belongs_to :user
  
  has_secure_token
  
  def self.create_new_token(user)
    return false if ApiToken.get_token(user)
    return ApiToken.create(user: user)
  end
  
  def self.get_token(user)
    ApiToken.where(user: user).first
  end
  
  def self.validate_token(key)
    token = ApiToken.includes(:user).where(token: key).first
    if token && token.user && !token.user.banned? 
      return token
    end
    
    false
  end
  
  def max_hits
    50
  end
  
  def reset
    self.touch(:reset_at)
    self.hits = 0
    self.save
  end
  
  def reset_interval
    1.hour
  end
  
  def on_cooldown?
    self.reset_at.nil? || self.reset_at <= Time.zone.now - self.reset_interval
  end
  
  def hit
    self.reset if self.on_cooldown?
    self.hits = self.hits + 1
    self.total_hits = self.total_hits + 1
    self.save
    
    return self.hits <= self.max_hits
  end
end
