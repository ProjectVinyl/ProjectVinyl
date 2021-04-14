class TagRule < ApplicationRecord

  def test(tag_ids)
    return if when_present.any? && (when_present & tag_ids).none?

    raise RuleNotFulfilledError, message if all_of.any? && (all_of - tag_ids).any?
    raise RuleNotFulfilledError, message if none_of.any? && (none_of & tag_ids).any?
    raise RuleNotFulfilledError, message if any_of.any? && (none_of & tag_ids).none?
  end

  def self.test(tag_ids)
    TagRule.all.find_each{ |rule| rule.test(tag_ids) }
    tag_ids
  end

  class RuleNotFulfilledError < RuntimeError
    
  end
end
