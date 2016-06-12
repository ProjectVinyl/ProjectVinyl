class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  has_many :votes
  has_one :album, as: :owner
  has_many :album_items, :through => :album
  
  def stars
    if self.album.nil?
      self.create_album(title: 'Starred Videos', 'description': 'My Favourites')
    end
    return self.album
  end
end
