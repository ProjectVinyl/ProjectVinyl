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
        return result
      end
      
      def uses(sym)
        if @data_pairs.key?(sym)
          return true
        end
        @children.each do |i|
          if i.uses(sym)
            return true
          end
        end
        return false
      end
      
      def root
        @parent || self
      end
      
      def cache_user(user)
        @users << user;
      end
      
      def user_id_for(username)
        if 1.is_a?(username.class)
          return username
        end
        if !@parent.nil?
          return self.root.user_id_for(username)
        end
        username = username.downcase
        if @users.length > 0 && @user_ids_cache.nil?
          @user_ids_cache = {}
          User.where('username IN (?)', @users).pluck(:id, :username).each do |u|
            @user_ids_cache[u[1].downcase] = u[0];
          end
        end
        if @user_ids_cache.key?(username)
          return @user_ids_cache[username]
        end
      end
      
      def self.interpret_opset(type, opset, sender)
        result = ElasticBuilder.new(nil)
        result.take_all(type, opset, sender)
        return result
      end
      
      def absorb_param(dest, opset, key)
        if (data = opset.shift) && data.length > 0
          dest << {term: {key.to_sym => data.strip}}
          @dirty = true
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
      end
      
      def absorb_param_if(dest, opset, key, condition)
        if (data = opset.shift) && data.length > 0
          if condition
            data = data.strip
            dest << {term: {key.to_sym => data}}
            @dirty = true
            return data
          end
        else
          raise LexerError, key + " Operator requires a data parameter"
        end
        return nil
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
        pair = {key => value}
        @data_pairs[key] = pair
        dest << {term: pair}
        @dirty = true
      end
      
      # reads all params and children into this group
      def take_all(type, opset, sender)
        while opset.length > 0
          op = opset.shift
          if op == ProjectVinyl::Search::Op::GROUP_END
            return
          end
          if op == ProjectVinyl::Search::Op::OR
            op_n = opset.peek(2)
            neg = false
            if op_n[0] == ProjectVinyl::Search::Op::NOT && op_n[1] == ProjectVinyl::Search::Op::GROUP_START
              neg = true
              op_n.shift
            end
            if op_n[0] == ProjectVinyl::Search::Op::GROUP_START
              opset.shift
            end
            child_group = ElasticBuilder.new(self)
            if neg
              child_group.negate
            end
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
              if neg
                child_group.negate
              end
              child_group.take_all(type, opset, sender)
              @anded_children << child_group
            end
            next
          end
          if op == ProjectVinyl::Search::Op::GROUP_START
            next
          end
          if op == ProjectVinyl::Search::Op::GROUP_END
            next
          end
          take_param(type, op, opset, sender)
        end
      end
      
      def take_prim(type, op, v, sender)
        if ((op == ProjectVinyl::Search::Op::AUDIO_ONLY && type != 'user') || (op == ProjectVinyl::Search::Op::HIDDEN && sender && sender.is_staff?))
          self.absorb_prim(@must, ProjectVinyl::Search::Op.name_of(op), v)
        end
      end
      
      # reads all the data operators into a group
      def take_param(type, op, opset, sender)
        if op == ProjectVinyl::Search::Op::TITLE
          self.absorb_param(@must, opset, type == 'user' ? 'username' : 'title')
        elsif op == ProjectVinyl::Search::Op::UPLOADER
          if op = self.absorb_param_if(@must_owner, opset, 'user_id', type != 'user')
            self.root.cache_user(op)
          end
        elsif op == ProjectVinyl::Search::Op::SOURCE
          self.absorb_param_if(@must, opset, 'source', type != 'user')
        elsif ProjectVinyl::Search::Op.primitive?(op)
          self.take_prim(type, op, true, sender)
        elsif ProjectVinyl::Search::Op.ranged?(op)
          @ranges.record(op, opset, false)
        elsif op == ProjectVinyl::Search::Op::NOT
          self.absorb(opset, "not") do |data|
            if data == ProjectVinyl::Search::Op::TITLE
              self.absorb_param(@must_not, opset, type == 'user' ? 'username' : 'title')
            elsif data == ProjectVinyl::Search::Op::UPLOADER
              if op = self.absorb_param_if(@must_not_owner, opset, 'user_id', type != 'user')
                self.root.cache_user(op)
              end
            elsif data == ProjectVinyl::Search::Op::SOURCE
              self.absorb_param_if(@must_not, opset, 'source', type != 'user')
            elsif ProjectVinyl::Search::Op.primitive?(data)
              self.take_prim(type, data, false, sender)
            elsif ProjectVinyl::Search::Op.ranged?(data)
              @ranges.record(data, opset, true)
            elsif data == ProjectVinyl::Search::Op::VOTE_U || data == ProjectVinyl::Search::Op::VOTE_D
              if type != 'user'
                @votes_not.record(data, opset, sender)
              end
            else
              @must_not << {term: {tags: data.strip}}
            end
          end
        elsif op == ProjectVinyl::Search::Op::VOTE_U || op == ProjectVinyl::Search::Op::VOTE_D
          if type != 'user'
            @votes.record(op, opset, sender)
          end
        else
          op = op.strip
          if op.length > 0
            @tags << op
            @must << {term: {tags: op}}
            @dirty = true
          end
        end
        return opset
      end
      
      def dirty
        return @dirty || @ranges.dirty || @votes.dirty || @votes_not.dirty
      end
      
      def negate
        @neg = !@neg
      end
      
      def self.__get(hash, key)
        if !hash.key?(key)
          hash[key] = []
        end
        return hash[key]
      end
      
      def baked_inclusions
        m = @must
        if @ranges.dirty
          m << @ranges.to_hash
        end
        if @votes.dirty
          m = m | @votes.to_hash
        end
        @must_owner.each do |o|
          if i = self.user_id_for(o[:term][:user_id])
            o[:term][:user_id] = i
            m << o
          end
        end
        @anded_children.each do |ac|
          m << ac.to_hash
        end
        return m
      end
      
      def baked_exclusions
        m = @must_not
        if @votes_not.dirty
          m = m | @votes_not.to_hash
        end
        @must_not_owner.each do |o|
          if i = self.user_id_for(o[:term][:user_id])
            o[:term][:user_id] = i
            m << o
          end
        end
        return m
      end
      
      def must(holder)
        m = @neg ? baked_exclusions : baked_inclusions
        if m.length > 0
          holder[:must] = m;
        end
        return holder
      end
      
      def must_not(holder)
        m = @neg ? baked_inclusions : baked_exclusions
        if m.length > 0
          holder[:must_not] = m;
        end
        return holder
      end
      
      def to_hash
        hash = {
          bool: {}
        }
        must hash[:bool]
        must_not hash[:bool]
        return hash
      end
      
      def bools
        { bool: must_not(must({})) }
      end
      
      def must_must_not(arr)
        if @must.length > 0 || @must_not.length > 0 || @ranges.dirty || @votes.dirty || @votes_not.dirty
          arr << bools
        end
        return arr
      end
      
      def should(arr)
        return ElasticBuilder.as_should(must_must_not(arr), @children)
      end
      
      def to_hash
        if @children.length == 0
          if @must.length > 0 || @must_not.length > 0 || @ranges.dirty || @votes.dirty || @votes_not.dirty || @anded_children.length > 0
            return bools
          end
          return {match_all: {}}
        end
        return {bool: {should: should([]), minimum_should_match: 1} }
      end
      
      def self.as_should(arr, groups)
        if groups.length > 0
          groups.each do |c|
            c.should(arr)
          end
        end
        return arr
      end
      
      def self.as_hash(groups)
        if groups.length == 1
          return groups[0].to_hash
        end
        return {bool: {should: ElasticBuilder.as_should([], groups), minimum_should_match: 1 } }
      end
    end
  end
end