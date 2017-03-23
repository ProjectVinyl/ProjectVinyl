require 'elasticsearch/model'

module Uncachable
  extend ActiveSupport::Concern
  
  def uncache
    self.touch(:cached_at)
  end
  
  def cache_bust(url)
    if self.cached_at
      url << '?' + self.cached_at.to_i.to_s
    end
    return url
  end
end