require 'projectvinyl/elasticsearch/range_query'
require 'projectvinyl/elasticsearch/vote_query'
require 'projectvinyl/search/lexer_error'
require 'projectvinyl/search/op'

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
        return self.root.user_id_for(username) if !@parent.nil?
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
          dest << { match: { key.to_sym => ".*#{data.strip}.*" } }
          @dirty = true
        else
          raise ProjectVinyl::Search::LexerError, key + " Operator requires a data parameter"
        end
      end

      def absorb_textual_if(dest, opset, key, condition)
        if (data = opset.shift) && !data.empty?
          if condition
            dest << { match: { key.to_sym => ".*#{data.strip}.*" } }
            @dirty = true
          end
        else
          raise ProjectVinyl::Search::LexerError, key + " Operator requires a data parameter"
        end
      end

      def absorb_param(dest, opset, key)
        if (data = opset.shift) && !data.empty?
          dest << { term: { key.to_sym => data.strip } }
          @dirty = true
        else
          raise ProjectVinyl::Search::LexerError, key + " Operator requires a data parameter"
        end
      end

      def absorb_param_if(dest, opset, key, condition)
        if (data = opset.shift) && !data.empty?
          if condition
            data = data.strip
            dest << { term: { key.to_sym => data } }
            @dirty = true
            return data
          end
        else
          raise ProjectVinyl::Search::LexerError, key + " Operator requires a data parameter"
        end
        nil
      end

      def absorb(opset, name)
        if !(data = opset.shift).nil?
          yield(data)
          @dirty = true
        else
          raise ProjectVinyl::Search::LexerError, name + " Operator requires a data parameter"
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
        if tag.include?('*')
          return {wildcard: { tags: tag } }
        end
        { term: { tags: tag } }
      end

      # reads all params and children into this group
      def take_all(type, opset, sender)
        until opset.length == 0
          op = opset.shift
          return if op == ProjectVinyl::Search::Op::GROUP_END
          if op == ProjectVinyl::Search::Op::OR
            op_n = opset.peek(2)
            neg = false
            if op_n[0] == ProjectVinyl::Search::Op::NOT && op_n[1] == ProjectVinyl::Search::Op::GROUP_START
              neg = true
              op_n.shift
            end
            opset.shift if op_n[0] == ProjectVinyl::Search::Op::GROUP_START
            child_group = ElasticBuilder.new(self)
            child_group.negate if neg
            child_group.take_all(type, opset, sender)
            @children << child_group
            next
          end
          if op == ProjectVinyl::Search::Op::AND
            op_n = opset.peek(2)
            neg = false
            if op_n[0] == ProjectVinyl::Search::Op::NOT
              neg = true
              op_n.shift
            end
            if op_n[0] == ProjectVinyl::Search::Op::GROUP_START
              opset.shift
              child_group = ElasticBuilder.new(self)
              child_group.negate if neg
              child_group.take_all(type, opset, sender)
              @anded_children << child_group
            end
            next
          end
          next if op == ProjectVinyl::Search::Op::GROUP_START
          next if op == ProjectVinyl::Search::Op::GROUP_END
          take_param(type, op, opset, sender)
        end
      end

      def take_prim(type, op, v, sender)
        if (op == ProjectVinyl::Search::Op::AUDIO_ONLY && type != 'user') || (op == ProjectVinyl::Search::Op::HIDDEN && sender && sender.is_staff?)
          self.absorb_prim(@must, ProjectVinyl::Search::Op.name_of(op), v)
        end
      end

      # reads all the data operators into a group
      def take_param(type, op, opset, sender)
        if op == ProjectVinyl::Search::Op::TITLE
          self.absorb_textual(@must, opset, type == 'user' ? 'username' : 'title')
        elsif op == ProjectVinyl::Search::Op::UPLOADER
          if op = self.absorb_param_if(@must_owner, opset, 'user_id', type != 'user')
            self.root.cache_user(op)
          end
        elsif op == ProjectVinyl::Search::Op::SOURCE
          self.absorb_textual_if(@must, opset, 'source', type != 'user')
        elsif ProjectVinyl::Search::Op.primitive?(op)
          self.take_prim(type, op, true, sender)
        elsif ProjectVinyl::Search::Op.ranged?(op)
          @ranges.record(op, opset, false)
        elsif op == ProjectVinyl::Search::Op::NOT
          self.absorb(opset, "not") do |data|
            if data == ProjectVinyl::Search::Op::TITLE
              self.absorb_textual(@must_not, opset, type == 'user' ? 'username' : 'title')
            elsif data == ProjectVinyl::Search::Op::UPLOADER
              if op = self.absorb_param_if(@must_not_owner, opset, 'user_id', type != 'user')
                self.root.cache_user(op)
              end
            elsif data == ProjectVinyl::Search::Op::SOURCE
              self.absorb_textual_if(@must_not, opset, 'source', type != 'user')
            elsif ProjectVinyl::Search::Op.primitive?(data)
              self.take_prim(type, data, false, sender)
            elsif ProjectVinyl::Search::Op.ranged?(data)
              @ranges.record(data, opset, true)
            elsif data == ProjectVinyl::Search::Op::VOTE_U || data == ProjectVinyl::Search::Op::VOTE_D
              @votes_not.record(data, opset, sender) if type != 'user'
            else
              @must_not << make_term(data.strip)
            end
          end
        elsif op == ProjectVinyl::Search::Op::VOTE_U || op == ProjectVinyl::Search::Op::VOTE_D
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

      def dirty
        @dirty || @ranges.dirty || @votes.dirty || @votes_not.dirty
      end

      def negate
        @neg = !@neg
      end

      def self.__get(hash, key)
        hash[key] = [] if !hash.key?(key)
        hash[key]
      end

      def baked_inclusions
        m = @must
        m << @ranges.to_hash if @ranges.dirty
        m |= @votes.to_hash if @votes.dirty
        @must_owner.each do |o|
          if i = self.user_id_for(o[:term][:user_id])
            o[:term][:user_id] = i
            m << o
          else
            raise ProjectVinyl::Search::LexerError, "User " + o[:term][:user_id] + " does not exist."
          end
        end
        @anded_children.each do |ac|
          m << ac.to_hash
        end
        m
      end

      def baked_exclusions
        m = @must_not
        m |= @votes_not.to_hash if @votes_not.dirty
        @must_not_owner.each do |o|
          if i = self.user_id_for(o[:term][:user_id])
            o[:term][:user_id] = i
            m << o
          else
            raise ProjectVinyl::Search::LexerError, "User " + o[:term][:user_id] + " does not exist."
          end
        end
        m
      end

      def must(holder)
        m = @neg ? baked_exclusions : baked_inclusions
        holder[:must] = m if !m.empty?
        holder
      end

      def must_not(holder)
        m = @neg ? baked_inclusions : baked_exclusions
        holder[:must_not] = m if !m.empty?
        holder
      end

      def bools
        { bool: must_not(must({})) }
      end

      def must_must_not(arr)
        if !@must.empty? || !@must_not.empty? || !@must_owner.empty? || !@must_not_owner.empty? || @ranges.dirty || @votes.dirty || @votes_not.dirty
          arr << bools
        end
        arr
      end

      def should(arr)
        ElasticBuilder.as_should(must_must_not(arr), @children)
      end

      def to_hash
        if @children.empty?
          if !@must.empty? || !@must_not.empty? || @ranges.dirty || @votes.dirty || @votes_not.dirty || !@anded_children.empty? || !@must_owner.empty? || !@must_not_owner.empty?
            return bools
          end
          return { match_all: {} }
        end
        { bool: { should: should([]), minimum_should_match: 1 } }
      end

      def self.as_should(arr, groups)
        if !groups.empty?
          groups.each do |c|
            c.should(arr)
          end
        end
        arr
      end

      def self.as_hash(groups)
        return groups[0].to_hash if groups.length == 1
        { bool: { should: ElasticBuilder.as_should([], groups), minimum_should_match: 1 } }
      end
    end
  end
end
