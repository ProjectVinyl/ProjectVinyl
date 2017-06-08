require 'elasticsearch/model'

module Uncachable
  extend ActiveSupport::Concern

  def uncache
    self.touch(:cached_at)
  end

  def cache_bust(url)
    url << '?' + self.cached_at.to_i.to_s if self.cached_at
    url
  end
end
