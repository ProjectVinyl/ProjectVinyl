#
# Implements a conditional version of counter_cache
#
# Usage:
#   In the child class:
#    belongs_to :parent
#    conditional_counter_cache :parent, :unread_childs, :unread, :counter_column
#   In the parent class:
#    has_many :unread_childs, ->{ where(unread: true) }, class_name: 'Child'
#
module Counterable
  extend ActiveSupport::Concern

  included do
    @conditional_counters = {}

    def self.__conditional_counters
      @conditional_counters
    end

    def self.conditional_counter_cache(my_association, their_association, test, counter_column)
      __conditional_counters[their_association] = {
        my_association: my_association,
        their_association: their_association,
        test: test,
        counter_column: counter_column
      }

      reflect_on_association(my_association).klass.include Countered
    end

    after_create :increment_conditional_counters
    after_destroy :decrement_conditional_counters
    after_update :reset_conditional_counters

    def self.reflect_on_conditional_association(association)
      __conditional_counters[association]
    end
  end

  module Countered
    extend ActiveSupport::Concern
    included do
      def self.reset_conditional_counters(id, *counters)
        object = find(id)
        counters.each do |association|
          child_class = reflect_on_association(association).klass
          counter_name = child_class.reflect_on_conditional_association(association)[:counter_column]
          their_relation = object.send(association)

          connection.update("UPDATE #{quoted_table_name} SET #{connection.quote_column_name(counter_name)} = #{their_relation.count} WHERE #{connection.quote_column_name(primary_key)} = #{object.id}", "#{name} UPDATE")
        end
      end
    end
  end

  private
  def increment_conditional_counters
    self.class.__conditional_counters.values.each do |counter|
      check = reflect_conditional_counter_association(counter)
      if check[:obj] && check[:test]
        check[:obj].increment(counter[:counter_column])
      end
    end
  end

  def decrement_conditional_counters
    self.class.__conditional_counters.values.each do |counter|
      check = reflect_conditional_counter_association(counter)
      if check[:obj] && check[:test]
        check[:obj].decrement(counter[:counter_column])
      end
    end
  end

  def reset_conditional_counters
    self.class.__conditional_counters.values.each do |counter|
      obj = send(counter[:my_association])
      obj.class.reset_conditional_counters(obj.id, counter[:their_association]) if obj
    end
  end

  def reflect_conditional_counter_association(counter)
    {
      obj: send(counter[:my_association]),
      test: send(counter[:test])
    }
  end
end
