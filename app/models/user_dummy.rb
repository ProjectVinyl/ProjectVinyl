class UserDummy
  include Roleable
  include Queues
  include WithFiles
  include Taggable
  
  def initialize(id)
    @id = id
    if id
      @username = 'Background Pony #' + id.to_s(36)
    else
      @username = 'Anonymous'
    end
  end

  def videos
    Video.where(user_id: @id)
  end

  attr_reader :id, :username

  def html_bio
    ''
  end
  
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

  def role
    -1
  end

  def is_dummy
    true
  end
end
