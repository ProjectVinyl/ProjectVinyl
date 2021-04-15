class TagRule < ApplicationRecord

  def self.has_tags_of(sym)
    getter = "__#{sym}_tags".to_sym
    setter = "__#{sym}_tags=".to_sym
    attr_accessor getter

    relation = "#{sym}_tags".to_sym

    define_method relation do
      val = send(getter)
      send(setter, ( val = Tag.where(id: send(sym)) ) ) if val.nil?
      val
    end
    define_method "#{sym}_tag_string".to_sym do
      send(relation).to_tag_string
    end
  end

  has_tags_of :when_present
  has_tags_of :all_of
  has_tags_of :none_of
  has_tags_of :any_of

  def test(tag_ids)
    return if when_present.any? && (when_present & tag_ids).none?

    raise RuleNotFulfilledError, message if all_of.any? && (all_of - tag_ids).any?
    raise RuleNotFulfilledError, message if none_of.any? && (none_of & tag_ids).any?
    raise RuleNotFulfilledError, message if any_of.any? && (any_of & tag_ids).none?
  end

  def self.test(tag_ids)
    TagRule.all.find_each{ |rule| rule.test(tag_ids) }
    tag_ids
  end

  class RuleNotFulfilledError < RuntimeError

  end
end
