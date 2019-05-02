module Tinted
  extend ActiveSupport::Concern
	
  def primary_color
    "##{Random.new(id).bytes(3).unpack("H*")[0]}"
  end
  
  def secondary_color
    "##{Random.new(id).bytes(3).unpack("H*")[2]}"
  end
end
