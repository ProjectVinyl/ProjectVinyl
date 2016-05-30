class Auth
  def self.is_signed_in(session)
    return !session[:current_user_id].nil? && User.where('id = ?', session[:current_user_id]).count > 0
  end
  
  def self.current_author(session)
    #user = User.where('id = ?', session[:current_user_id])
    #if user
      return Artist.where('id = ?', user.artist_id).first
    #end
    #return nil
  end
  
  def self.current_user(session)
    return nil #User.where('id = ?', session[:current_user_id]).first
  end
end