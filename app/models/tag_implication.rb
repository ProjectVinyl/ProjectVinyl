class TagImplication < ActiveRecord::Base
  belongs_to :implicator, class_name: 'Tag', foreign_key: 'tag_id'
  belongs_to :implication, class_name: 'Tag', foreign_key: 'implied_id'
end
