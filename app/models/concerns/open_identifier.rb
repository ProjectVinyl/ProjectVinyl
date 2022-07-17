module OpenIdentifier
  extend ActiveSupport::Concern

  included do
    scope :encode_open_id, ->(i) { i.to_s(36).rjust(6, '0') }
    scope :decode_open_id, ->(s) { s.to_i(36) }
  end

  def oid
    self.class.encode_open_id(id)
  end
  
  def oref
    "#{self.class.name.downcase}_#{oid}"
  end
end
