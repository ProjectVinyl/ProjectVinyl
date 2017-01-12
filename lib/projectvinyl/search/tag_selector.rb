require 'projectvinyl/search/op'

module ProjectVinyl
  module Search
    class TagSelector
      
      def initialize(sender, search_terms)
        @user = sender
        @opset = Op.loadOPS(search_terms)
        @type = "unknown"
      end
      
      def query(page, limit)
        @page = page
        @limit = limit
        return self
      end
      
      def videos
        @type = "video"
        v_query = "SELECT v.* FROM videos v, users WHERE v.hidden = false AND v.duplicate_id = 0 AND v.user_id = users.id"
        groups = MatchingGroup.interpret_opset(@opset)[0]
        if groups.length > 0
          groups = groups.map do |group|
            group.to_video_sql(@user)
          end
          v_query << " AND ( " + groups.join(' OR ') + " )"
        end
        v_query << " GROUP BY v.id"
        @main_sql = v_query
        return self
      end
      
      def users
        @type = "user"
        v_query = "SELECT a.* FROM users a"
        groups = MatchingGroup.interpret_opset(@opset)[0]
        if groups.length > 0
          groups = groups.map do |group|
            group.to_user_sql(@user)
          end
          v_query << " WHERE " + groups.join(' OR ')
        end
        @main_sql = v_query
        @page = page
        @limit = limit
        return self
      end
      
      def order_by(ordering)
        @ordering = ordering
        return self
      end
      
      def offset(off)
        @offset = off
        return self
      end
      
      def order(session, ordering, ascending)
        @ordering = "v.created_at"
        if @type == 'video'
          if ordering == 1
            @ordering = "v.created_at, v.updated_at"
          elsif ordering == 2
            @ordering = "v.score, v.created_at, v.updated_at"
          elsif ordering == 3
            @ordering = "v.length, v.created_at, v.updated_at"
          elsif ordering == 4
            if @page == 0
              ordering_columns = ["v.length","v.created_at","v.updated_at","v.score","v.views","v.description"]
              session[:random_ordering] = "'" + ordering_columns[rand(0..ordering_columns.length)] + "','" + ordering_columns[rand(0..ordering_columns.length)] + "'"
            end
            @ordering = session[:random_ordering]
          end
        elsif @type == 'user'
          if ordering == 1 || ordering == 2 || ordering == 3
            @ordering = "a.username, a.created_at, a.updated_at"
          elsif ordering == 4
            if @page == 0
              ordering_columns = ["a.username","a.email","a.encrypted_password","a.updated_at"]
              session[:random_ordering] = "'" + ordering_columns[Random.new(0..ordering_columns.length)] + "','" + ordering_columns[Random.new(0..ordering_columns.length)] + "'"
            end
            @ordering = session[:random_ordering]
          else
            @ordering = "a.username"
          end
        end
        if !ascending
          @ordering = @ordering.gsub(', ', ' DESC, ') + " DESC"
        end
        return self
      end
      
      def exec()
        @count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM (" + @main_sql + ") AS `matches`;").first[0].to_i
        if @page.nil?
          @page = 0
        end
        @pages = @count / @limit
        
        if @count > 0 && (@pages * @limit) == @count
          @pages -= 1
        end
        if @count <= @page * @limit || @page < 0
          @page = @pages
        end
        if @offset == -1
          @offset = rand(@count)
        end
        sql = @main_sql + " ORDER BY " + @ordering + " LIMIT " + @limit.to_s + " OFFSET " + (@offset ? @offset : (@page * @limit)).to_s + ";"
        if @type == 'video'
          @records = Video.find_by_sql(sql)
          ActiveRecord::Associations::Preloader.new.preload(@records, :tags)
        else
          @records = User.find_by_sql(sql)
          ActiveRecord::Associations::Preloader.new.preload(@records, [:tags, :user_badges])
        end
        return self
      end
      
      def sanitize(arguments)
        return Tag.sanitize_sql(arguments)
      end
      
      def system_tag_matcher(data, matcher, suffex)
        if matcher
          return self.sanitize([matcher, '%' + data.to_s + '%']) + suffex
        end
        return ""
      end
      
      def records
        @records
      end
      
      def page
        @page
      end
      
      def page_size
        @limit
      end
      
      def pages
        @pages
      end
      
      def count
        @count
      end
      
      def length
        @count
      end
    end
  end
end
