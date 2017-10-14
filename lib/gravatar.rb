require 'digest/md5'

module Gravatar
  def self.avatar_for(email, params)
    email = Digest::MD5.hexdigest((email || '').strip.downcase)
    params = params.to_param
    query = params.empty? ? '' : '?' + params
    "//www.gravatar.com/avatar/#{email}.png#{query}"
  end
end
