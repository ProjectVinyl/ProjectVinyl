class UserAnon < UserDummy
  def self.anon_id(session)
    if !session.has_key? :session_id
      # LAME we have to write to the session to get it to initialize itself
      # the following line could be anything that writes to the session
      # except don't write to session_id, because that's what we need
      session[:id] = session[:id]
    end
    
    -Comment.decode_open_id(session[:session_id][0..3])
  end
  
  def initialize(session)
    @id = -UserAnon.anon_id(session)
    @username = "Background Pony ##{Comment.encode_open_id(@id)}"
  end
  
  def videos
    Video.none
  end
  
  def votes
    Vote.none
  end
end
