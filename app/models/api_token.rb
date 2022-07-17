class ApiToken < ApplicationRecord
  belongs_to :user

  has_secure_token

  scope :for_user, ->(user, create: false) {
    token = where(user: user).first
    return ApiToken.create(user: user) if token.nil?
    token
  }
  scope :create_new_token, ->(user) {
    return false if for_user(user)
    return ApiToken.create(user: user)
  }

  def self.validate_token(key)
    token = ApiToken.includes(:user).where(token: key).first
    return token if token && token.user && !token.user.banned?
    false
  end

  def max_hits
    50
  end

  def reset
    touch(:reset_at)
    self.hits = 0
    save
  end

  def reset_interval
    1.hour
  end

  def on_cooldown?
    self.reset_at.nil? || reset_at <= Time.zone.now - reset_interval
  end

  def hit
    reset if on_cooldown?
    self.hits = self.hits + 1
    self.total_hits = self.total_hits + 1
    self.save

    return hits <= max_hits
  end
end
