class UserDummy
  include Roleable
  include Queues
  include WithFiles
  include Taggable
  include Tinted
  
  def initialize(id)
    @id = id < 0 ? -id : id
    @username = "Background Pony ##{Comment.encode_open_id(@id).upcase}"
  end

  def videos
    Video.where(user_id: @id)
  end
  
  def votes
    Vote.where(user_id: @id)
  end
  
  attr_reader :id, :username

  def avatar
    '/images/default-avatar.png'
  end
  
  def tags_changed
  end
  
  def tag_string
    ''
  end
  
  def link
    ''
  end

  def admin?
    self.is_admin?
  end

  def contributor?
    false
  end

  def banned?
    false
  end
  
  def online?
    false
  end
  
  def role
    -1
  end

  def is_dummy
    true
  end
end
