module Unlistable
  extend ActiveSupport::Concern

  included do
    scope :privated, -> { where(listing: 2) }
    scope :unlisted, -> { where(listing: 1) }
    scope :listed, -> { where(hidden: false, listing: 0) }
    
    scope :unprivated, -> { where('listing < 2') }
  end

  def privated?
    hidden || listing == 2
  end

  def unlisted?
    !hidden && listing == 1
  end

  def listed?
    !hidden && listing == 0
  end

  def owned_by(user)
    user && (self.user_id == user.id || (self.hidden == false && user.is_staff?))
  end

  def visible_to?(user)
    listed? || owned_by(user)
  end
end
