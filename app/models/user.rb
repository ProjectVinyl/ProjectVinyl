class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  has_many :votes
  has_one :album, as: :owner
  has_many :album_items, :through => :album
  has_many :notifications
  belongs_to :artist
  
  def stars
    if self.album.nil?
      self.create_album(title: 'Starred Videos', 'description': 'My Favourites')
    end
    return self.album
  end
  
  def username
    if self.artist_id
      return self.artist.name
    end
    return 'Background Pony #' + self.id.to_s
  end
  
  def avatar
    if self.artist_id
      return '/avatar/' + self.artist_id.to_s
    end
    return '/images/default-avatar.png'
  end
  
  def link
    if self.artist_id
      return '/artist/' + self.artist_id.to_s + '-' + ApplicationHelper.url_safe(self.username)
    end
    return '/users/edit'
  end
  
  def send_notification(message, source)
    self.notifications.create(message: message, source: source)
    self.notification_count = self.notification_count + 1
    self.save
  end
end
