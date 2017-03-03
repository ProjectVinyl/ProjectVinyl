require 'projectvinyl/search/range_query'

module ProjectVinyl
  module Search
    class MatchingGroup
      def initialize
        @neg = false
        @dirty = false
        @title_queries = []
        @title_queries_exclusions = []
        @source_queries = []
        @source_queries_exclusions = []
        @user_queries = []
        @user_queries_exclusions = []
        @like_queries = []
        @like_queries_exclusions = []
        @dislike_queries = []
        @dislike_queries_exclusions = []
        @inclusions = []
        @exclusions = []
        @children = []
        @range_queries = []
        @audio_only = nil
      end
      
      def self.interpret_opset(type, opset)
        groupings = []
        current_group = MatchingGroup.new
        while opset.length > 0
          op = opset.shift
          if op == Op::OR
            if current_group.dirty
              groupings << current_group
            end
            current_group = MatchingGroup.new
          elsif op == Op::AND
            opset = current_group.take_param(type, opset.shift, opset)
          elsif op == Op::GROUP_START
            child = self.interpret_opset(type, opset)
            current_group.child(child[0])
            opset = child[1]
          elsif op == Op::GROUP_END
            if current_group.dirty
              groupings << current_group
            end
            return [groupings,opset]
          elsif op == Op::OR && opset.peek(1) == Op::GROUP_START
            opset.shift
            child = self.interpret_opset(type, opset)
            child[0].negate
            if current_group
              current_group.child(child[0])
            else
              current_group = child[0]
            end
            opset = child[1]
          else
            opset = current_group.take_param(type, op, opset)
          end
        end
        if current_group.dirty
          groupings << current_group
        end
        return [groupings,opset]
      end
      
      def child(groupings)
        if groupings && groupings.length > 0
          @children = @children | groupings.select do |group|
            group.dirty
          end
          @dirty = true
        end
      end
      
      def absorb_param(dest, opset, name)
        if (data = opset.shift) && data.length > 0
          dest << data.strip
          @dirty = true
        else
          raise LexerError, name + " Operator requires a data parameter"
        end
      end
      
      def absorb_param_if(dest, opset, name, condition)
        if (data = opset.shift) && data.length > 0
          if condition
            dest << data.strip
            @dirty = true
          end
        else
          raise LexerError, name + " Operator requires a data parameter"
        end
      end
      
      def absorb(opset, name)
        if !(data = opset.shift).nil?
          yield(data)
          @dirty = true
        else
          raise LexerError, name + " Operator requires a data parameter"
        end
      end
      
      def take_param(type, op, opset)
        if op == Op::TITLE
          self.absorb_param(@title_queries, opset, "Title")
        elsif op == Op::UPLOADER
          self.absorb_param_if(@user_queries, opset, "Uploader", type != 'user')
        elsif op == Op::SOURCE
          self.absorb_param_if(@source_queries, opset, "Source", type != 'user')
        elsif op == Op::VOTE_U
          self.absorb_param_if(@like_queries, opset, "Upvoted", type != 'user')
        elsif op == Op::VOTE_D
          self.absorb_param_if(@dislike_queries, opset, "Downvoted", type != 'user')
        elsif op == Op::AUDIO_ONLY
          @audio_only = true
          @dirty = true
        elsif Op.ranged?(op)
          @range_queries << RangeQuery.new(op, opset, false)
          @dirty = true
        elsif op == Op::NOT
          self.absorb(opset, "Not") do |data|
            if data == Op::TITLE
              self.absorb_param(@title_queries_exclusions, opset, "Title")
            elsif data == Op::UPLOADER
              self.absorb_param_if(@user_queries_exclusions, opset, "Uploader", type != 'user')
            elsif data == Op::SOURCE
              self.absorb_param_if(@source_queries_exclusions, opset, "Source", type != 'user')
            elsif op == Op::VOTE_U
              self.absorb_param_if(@like_queries_exclusions, opset, "Upvoted", type != 'user')
            elsif op == Op::VOTE_D
              self.absorb_param_if(@dislike_queries_exclusions, opset, "Downvoted", type != 'user')
            elsif data == Op::AUDIO_ONLY
              @audio_only = false
            elsif Op.ranged?(data)
              @range_queries << RangeQuery.new(data, opset, true)
            else
              @exclusions << data.strip
            end
          end
        else
          op = op.strip
          if op.length > 0
            @inclusions << op
            @dirty = true
          end
        end
        return opset
      end
      
      def dirty
        return @dirty
      end
      
      def negate
        @neg = !@neg
      end
      
      def to_video_sql(sender)
        sql = []
        if @title_queries.length > 0
          @title_queries.uniq.each do |title|
            sql << Tag.sanitize_sql(["title LIKE ?", '%' + title + '%'])
          end
        end
        if @title_queries_exclusions.length > 0
          @title_queries_exclusions.uniq.each do |title|
            sql << Tag.sanitize_sql(["title NOT LIKE ?", '%' + title + '%'])
          end
        end
        if @user_queries.length > 0
          @user_queries.uniq.each do |user|
            sql << Tag.sanitize_sql(["users.username LIKE ?", '%' + user + '%'])
          end
        end
        if @user_queries_exclusions.length > 0
          @user_queries_exclusions.uniq.each do |user|
            sql << Tag.sanitize_sql(["users.username NOT LIKE ?", '%' + user + '%'])
          end
        end
        if sender
          if @like_queries.length > 0
            @like_queries.uniq.each do |user|
              if user == 'nil'
                user = sender.username
              end
              if sender.contributor? || user == sender.username
                sql << Tag.sanitize_sql(["vusers.username LIKE ?", '%' + user + '%'])
              end
            end
          end
          if @like_queries_exclusions.length > 0
            @like_queries_exclusions.uniq.each do |user|
              if user == 'nil'
                user = sender.username
              end
              if sender.contributor? || user == sender.username
                sql << Tag.sanitize_sql(["vusers.username NOT LIKE ?", '%' + user + '%'])
              end
            end
          end
          if @dislike_queries.length > 0
            @dislike_queries.uniq.each do |user|
              if user == 'nil'
                user = sender.username
              end
              if sender.contributor? || user == sender.username
                sql << Tag.sanitize_sql(["dusers.username LIKE ?", '%' + user + '%'])
              end
            end
          end
          if @dislike_queries_exclusions.length > 0
            @dislike_queries_exclusions.uniq.each do |user|
              if user == 'nil'
                user = sender.username
              end
              if sender.contributor? || user == sender.username
                sql << Tag.sanitize_sql(["dusers.username NOT LIKE ?", '%' + user + '%'])
              end
            end
          end
        end
        if @range_queries.length > 0
          @range_queries.uniq.each do |r|
            sql << r.to_sql
          end
        end
        if @exclusions.length > 0
          sql << Tag.sanitize_sql(["(SELECT COUNT(*) FROM video_genres g, tags t LEFT JOIN tags q ON t.id = q.alias_id WHERE t.id = g.tag_id AND g.video_id = v.id AND (t.name IN (?) OR q.name IN (?))) = 0", @exclusions, @exclusions])
        end
        if @inclusions.length > 0
          sql << Tag.sanitize_sql(["(SELECT COUNT(*) FROM video_genres g, tags t LEFT JOIN tags q ON t.id = q.alias_id WHERE t.id = g.tag_id AND g.video_id = v.id AND (t.name IN (?) OR q.name IN (?))) = ?", @inclusions, @inclusions, @inclusions.length])
        end
        if !@audio_only.nil?
          sql << Tag.sanitize_sql(["audio_only = ?", @audio_only])
        end
        if @children.length > 0
          children = @children.map do |c|
            c.to_video_sql(sender)
          end
          sql << '(' + children.join(' OR ') + ')'
        end
        return (@neg ? " NOT " : "") + "(" + sql.join(' AND ') + ")"
      end
      
      def to_user_sql(sender)
        sql = []
        if @title_queries.length > 0
          @title_queries.uniq.each do |user|
            sql << Tag.sanitize_sql(["username LIKE ?", '%' + user + '%'])
          end
        end
        if @title_queries_exclusions.length > 0
          @title_queries_exclusions.uniq.each do |user|
            sql << Tag.sanitize_sql(["username NOT LIKE ?", '%' + user + '%'])
          end
        end
        if @exclusions.length > 0
          sql << Tag.sanitize_sql(["(SELECT COUNT(*) FROM artist_genres g, tags t LEFT JOIN tags q ON t.id = q.alias_id WHERE t.id = g.tag_id AND g.user_id = a.id AND (t.name IN (?) OR q.name IN (?))) = 0", @exclusions, @exclusions])
        end
        if @inclusions.length > 0
          sql << Tag.sanitize_sql(["(SELECT COUNT(*) FROM artist_genres g, tags t LEFT JOIN tags q ON t.id = q.alias_id WHERE t.id = g.tag_id AND g.user_id = a.id AND (t.name IN (?) OR q.name IN (?))) = ?", @inclusions, @inclusions, @inclusions.length])
        end
        if @children.length > 0
          children = @children.map do |c|
            c.to_user_sql(sender)
          end
          sql << '(' + children.join(' OR ') + ')'
        end
        return (@neg ? " NOT " : "") + "(" + sql.join(' AND ') + ")"
      end
    end
  end
end