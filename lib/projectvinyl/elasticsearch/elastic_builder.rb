require 'projectvinyl/elasticsearch/range_query'
require 'projectvinyl/elasticsearch/text_query'
require 'projectvinyl/elasticsearch/vote_query'
require 'projectvinyl/elasticsearch/lexer_error'
require 'projectvinyl/elasticsearch/input_error'
require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class ElasticBuilder
      def initialize(parent)
        @data_pairs = {}

        @parent = parent
        @children = []
        @anded_children = []
        @must = []
        @must_not = []
        @neg = false
        @ranges = RangeQuery.new
        @votes = VoteQuery.new(self)
        @votes_not = VoteQuery.new(self)

        @must_owner = []
        @must_not_owner = []

        @users = []
        @tags = []
      end

      def tags
        result = []
        result |= @tags
        @children.each do |i|
          result |= i.tags
        end
        result
      end

      def uses(sym)
        return true if @data_pairs.key?(sym)
        @children.each do |i|
          return true if i.uses(sym)
        end
        false
      end

      def root
        @parent || self
      end

      def cache_user(user)
        @users << user
      end

      def user_id_for(username)
        id = username.to_i
        return id if id.to_s == username
        return root.user_id_for(username) if !@parent.nil?
        username = username.downcase
        if !@users.empty? && @user_ids_cache.nil?
          @user_ids_cache = {}
          User.where('LOWER(username) IN (?)', @users).pluck(:id, :username).each do |u|
            @user_ids_cache[u[1].downcase] = u[0]
          end
        end
        return @user_ids_cache[username] if @user_ids_cache.key?(username)
      end

      def self.interpret_opset(type, opset, sender)
        result = ElasticBuilder.new(nil)
        result.take_all(type, opset, sender)
        result
      end

      def absorb_textual(dest, opset, key)
        if (data = opset.shift) && !data.empty?
          absorb_textual_unchecked(dest, key, data)
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
      end

      def absorb_textual_unchecked(dest, key, data)
        dest << TextQuery.parse(key, data)
        @dirty = true
      end

      def absorb_textual_if(dest, opset, key, condition)
        if (data = opset.shift) && !data.empty?
          if condition
            absorb_textual_unchecked(dest, key, data)
          end
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
      end

      def absorb_param(dest, opset, key)
        if (data = opset.shift) && !data.empty?
          dest << { term: { key.to_sym => data.strip } }
          @dirty = true
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
      end

      def obsorb_user_id(dest, opset, key, sender, condition)
        if (data = opset.shift) && !data.empty?
          if condition
            data = data.strip
            if sender && data == 'nil'
              data = sender.id
            end
            dest << { term: { key.to_sym => data } }
            @dirty = true
            return data
          end
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
        nil
      end

      def absorb(opset, name)
        if !(data = opset.shift).nil?
          yield(data)
          @dirty = true
        else
          raise LexerError, name + " Operator requires a data parameter"
        end
      end

      def absorb_prim(dest, key, value)
        key = key.to_sym
        if @data_pairs.key?(key)
          @data_pairs[key][key] = value
          return
        end
        pair = { key => value }
        @data_pairs[key] = pair
        dest << { term: pair }
        @dirty = true
      end

      def make_term(tag)
        return {wildcard: { tags: tag } } if tag.include?('*')
        {
          term: {
            tags: tag
          }
        }
      end

      # reads all params and children into this group
      def take_all(type, opset, sender)
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
            child_group.take_all(type, opset, sender)
            @children << child_group
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
              child_group.take_all(type, opset, sender)
              @anded_children << child_group
            end
            next
          end
          next if op == Op::GROUP_START
          next if op == Op::GROUP_END
          take_param(type, op, opset, sender)
        end
      end

      def take_prim(type, op, v, sender)
        if (op == Op::AUDIO_ONLY && type != 'user') || (op == Op::HIDDEN && sender && sender.is_staff?)
          self.absorb_prim(@must, Op.name_of(op), v)
        end
      end

      # reads all the data operators into a group
      def take_param(type, op, opset, sender)
        if op == Op::TITLE
          absorb_textual(@must, opset, type == 'user' ? 'username' : 'title')
        elsif op == Op::UPLOADER
          if op = obsorb_user_id(@must_owner, opset, 'user_id', sender, type != 'user')
            root.cache_user(op)
          end
        elsif op == Op::SOURCE
          absorb_textual_if(@must, opset, 'source', type != 'user')
        elsif Op.primitive?(op)
          take_prim(type, op, true, sender)
        elsif Op.ranged?(op)
          @ranges.record(op, opset, false)
        elsif data == Op::ASPECT
          absorb_param(@must, opset, 'aspect')
        elsif op == Op::NOT
          absorb(opset, "not") do |data|
            if data == Op::TITLE
              absorb_textual(@must_not, opset, type == 'user' ? 'username' : 'title')
            elsif data == Op::UPLOADER
              if op = obsorb_user_id(@must_not_owner, opset, 'user_id', sender, type != 'user')
                root.cache_user(op)
              end
            elsif data == Op::SOURCE
              absorb_textual_if(@must_not, opset, 'source', type != 'user')
            elsif Op.primitive?(data)
              take_prim(type, data, false, sender)
            elsif Op.ranged?(data)
              @ranges.record(data, opset, true)
            elsif data == Op::ASPECT
              self.absorb_param(@must_not, opset, 'aspect')
            elsif data == Op::VOTE_U || data == Op::VOTE_D
              @votes_not.record(data, opset, sender) if type != 'user'
            else
              @must_not << make_term(data.strip)
            end
          end
        elsif op == Op::VOTE_U || op == Op::VOTE_D
          @votes.record(op, opset, sender) if type != 'user'
        else
          op = op.strip
          if !op.empty?
            @tags << op
            @must << make_term(op)
            @dirty = true
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

      def __dirty?
        @ranges.dirty || @votes.dirty || @votes_not.dirty
      end

      def empty?
        @must.empty? && @must_not.empty? && @must_owner.empty? && @must_not_owner.empty? && !__dirty?
      end

      def to_hash
        if @children.empty?
          return bools if !empty? || !@anded_children.empty?
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
        @children.each {|c| c.should(arr) }
        arr
      end

      private
      def compile_terms(m, ranges, votes, owners, anded)
        m << ranges.to_hash if ranges && ranges.dirty
        m |= votes.to_hash if votes.dirty

        owners.each do |o|
          if i = user_id_for(o[:term][:user_id])
            o[:term][:user_id] = i
            m << o
          else
            raise InputError, "User " + o[:term][:user_id] + " does not exist."
          end
        end

        if anded
          anded.each {|ac| m << ac.to_hash }
        end

        m
      end

      def append_terms(holder, exclude, key)
        value = exclude ? compile_terms(@must_not, nil, @votes_not, @must_not_owner, nil) : compile_terms(@must, @ranges, @votes, @must_owner, @anded_children)
        holder[key] = value if !value.empty?
        holder
      end

      def bools
        { bool: append_terms(append_terms({}, @neg, :must), !@neg, :must_not) }
      end
    end
  end
end
