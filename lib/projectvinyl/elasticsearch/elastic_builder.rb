require 'projectvinyl/elasticsearch/user_id_cache'
require 'projectvinyl/elasticsearch/range_query'
require 'projectvinyl/elasticsearch/text_query'
require 'projectvinyl/elasticsearch/vote_query'
require 'projectvinyl/elasticsearch/lexer_error'
require 'projectvinyl/elasticsearch/input_error'
require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class ElasticBuilder
      attr_reader :user_cache

      def self.interpret_opset(opset, sender = nil)
        result = ElasticBuilder.new
        result.take_all(opset, sender)
        result
      end

      def initialize(parent = nil)
        @parent = parent
        @siblings = []
        @groups = []

        @tags = []
        @data_pairs = {}
        @user_cache = UserIdCache.new

        @neg = false
        @must = []
        @must_not = []
        @ranges = RangeQuery.new
        @votes = VoteQuery.new(self)
        @votes_not = VoteQuery.new(self)
      end

      def tags
        result = []
        result |= @tags
        @siblings.each do |i|
          result |= i.tags
        end
        result
      end

      def uses(sym)
        return true if @data_pairs.key?(sym)
        @siblings.each do |i|
          return true if i.uses(sym)
        end
        false
      end

      def root
        @parent || self
      end

      def obsorb_textual(dest, opset)
        dest << TextQuery.read(opset)
        @dirty = true
      end

      def obsorb_prim(dest, op, opset, sender)
        key = opset.shift_data(op, 'field')
        value = opset.shift_data(op, 'value')
        key = key.to_sym
        if key == :hidden && !(sender && sender.is_staff?)
          return
        end

        if @data_pairs.key?(key)
          @data_pairs[key][key] = value
          return
        end

        pair = { key => value }
        @data_pairs[key] = pair
        dest << { term: pair }
        @dirty = true
      end

      def obsorb_term(op, opset, dest)
        field = opset.shift_data(op, 'field')
        value = opset.shift_data(op, 'value').strip
        return if value.empty?
        @tags << value
        dest << TextQuery.make_term(field, value)
        @dirty = true
      end

      # reads all params and children into this group
      def take_all(opset, sender)
        until opset.length == 0
          op = opset.shift

          return if op == Op::GROUP_END

          if op == Op::OR
            op_n = opset.peek(2)
            neg = false
            if op_n[0] == Op::NOT && op_n[1] == Op::GROUP_START
              neg = true
              op_n.shift
            end
            opset.shift if op_n[0] == Op::GROUP_START
            child_group = ElasticBuilder.new(self)
            child_group.negate if neg
            child_group.take_all(opset, sender)
            @siblings << child_group
            next
          end

          if op == Op::AND
            op_n = opset.peek(2)
            neg = false
            if op_n[0] == Op::NOT
              neg = true
              op_n.shift
            end

            if op_n[0] == Op::GROUP_START
              opset.shift
              child_group = ElasticBuilder.new(self)
              child_group.negate if neg
              child_group.take_all(opset, sender)
              @groups << child_group
            end

            next
          end

          next if op == Op::GROUP_END || op == Op::GROUP_START

          take_param(op, opset, sender)
        end
      end

      # reads all the data operators into a group
      def take_param(op, opset, sender)

        if op == Op::MY
          @votes.record(op, opset, sender)
        elsif op == Op::TEXT_EQUAL
          obsorb_textual(@must, opset)
        elsif op == Op::EQUAL
          obsorb_prim(@must, op, opset, sender)
        elsif (op == Op::LESS_THAN || op == Op::GREATER_THAN)
          @ranges.record(op, opset, false)
        elsif op == Op::HAS
          obsorb_term(op, opset, @must)
        elsif op == Op::NOT
          @dirty = true
          opset.shift_data(op, 'term') do |data|
            if data == Op::MY
              @votes_not.record(data, opset, sender)
            elsif data == Op::TEXT_EQUAL
              obsorb_textual(@must_not, opset)
            elsif data == Op::EQUAL
              obsorb_prim(@must_not, data, opset, sender)
            elsif data == Op::HAS
              obsorb_term(data, opset, @must_not)
            elsif (data == Op::LESS_THAN || data == Op::GREATER_THAN)
              @ranges.record(data, opset, true)
            end
          end
        end

        opset
      end

      def negate
        @neg = !@neg
      end

      def dirty
        @dirty || __dirty?
      end

      def empty?
        @must.empty? && @must_not.empty? && !__dirty?
      end

      def to_hash
        if @siblings.empty?
          return bools if !empty? || !@groups.empty?
          return { match_all: {} }
        end

        {
          bool: {
            should: should([]),
            minimum_should_match: 1
          }
        }
      end

      def should(arr)
        arr << bools if !empty?
        @siblings.each {|c| c.should(arr) }
        arr
      end

      private
      def __dirty?
        @ranges.dirty || @votes.dirty || @votes_not.dirty
      end

      def compile_terms(m, ranges, votes, groups)
        m = ranges.compile(m) if ranges
        m = votes.compile(m)
        groups.each {|group| m << group.to_hash } if groups

        m
      end

      def compile(holder, exclude, key)
        value = exclude ? compile_terms(@must_not, nil, @votes_not, nil) : compile_terms(@must, @ranges, @votes, @groups)
        holder[key] = value if !value.empty?
        holder
      end

      def bools
        { bool: compile(compile({}, @neg, :must), !@neg, :must_not) }
      end
    end
  end
end
