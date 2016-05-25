class Auth
  def self.is_signed_in(session)
    return !session[:current_user_id].nil? && Artist.where('id = ?', session[:current_user_id]).count > 0
  end
end