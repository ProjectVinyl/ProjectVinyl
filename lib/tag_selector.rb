class LexerError < SyntaxError
end

class RangeQuery
  LENGTH_GT = -9
  LENGTH_LT = -10
  SCORE_GT = -11
  SCORE_LT = -12
  
  def initialize(op, opset, invert)
    @greater_than = op == LENGTH_GT || op == SCORE_GT
    if invert
      @greater_than = !@greater_than
    end
    @field = op == LENGTH_GT || op == LENGTH_LT ? 'length' : 'score'
    if !(@value = opset.shift) || @value.length == 0
      @value = 0
    else
      if @field == 'length'
        @value = Ffmpeg.from_h_m_s(@value)
      else
        @value = @value.to_i
      end
    end
  end
  
  def to_sql
    Tag.sanitize_sql([@field + (@greater_than ? ' > ?' : ' < ?'), @value])
  end
end

class VideoMatchingGroup
  OR = -1
  AND = -2
  NOT = -3
  TITLE = -4
  UPLOADER = -5
  SOURCE = -6
  GROUP_START = -7
  GROUP_END = -8
  LENGTH_GT = -9
  LENGTH_LT = -10
  SCORE_GT = -11
  SCORE_LT = -12
  AUDIO_ONLY = -13
  
  def initialize
    @neg = false
    @dirty = false
    @title_queries = []
    @title_queries_exclusions = []
    @source_queries = []
    @source_queries_exclusions = []
    @user_queries = []
    @user_queries_exclusions = []
    @inclusions = []
    @exclusions = []
    @children = []
    @range_queries = []
    @audio_only = nil
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
  
  def absorb_param(dest, opset, name, condition)
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
    if op == TITLE
      self.absorb_param(@title_queries, opset, "Title")
    elsif op == UPLOADER
      self.absorb_param_if(@user_queries, opset, "Uploader", type != user)
    elsif op == SOURCE
      self.absorb_param_if(@source_queries, opset, "Source", type != user)
    elsif op == NOT
      self.absorb(opset, "Not") do |data|
        if data == TITLE
          self.absorb_param(@title_queries_exclusions, opset, "Title")
        elsif data == UPLOADER
          self.absorb_param_if(@user_queries_exclusions, opset, "Uploader", type != user)
        elsif data == SOURCE
          self.absorb_param_if(@source_queries_exclusions, opset, "Uploader", type != user)
        elsif data == AUDIO_ONLY
          @audio_only = false
        elsif TagSelector.ranged?(data)
          @range_queries << RangeQuery.new(data, opset, true)
        else
          @exclusions << data.strip
        end
      end
    elsif op == AUDIO_ONLY
      @audio_only = true
      @dirty = true
    elsif TagSelector.ranged?(op)
      @range_queries << RangeQuery.new(op, opset, false)
      @dirty = true
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
  
  def to_video_sql
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
        c.to_video_sql
      end
      sql << '(' + children.join(' OR ') + ')'
    end
    return sql.join(' AND ')
  end
  
  def to_user_sql
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
        c.to_user_sql
      end
      sql << '(' + children.join(' OR ') + ')'
    end
    return (@neg ? " NOT " : "") + "(" + sql.join(' AND ') + ")"
  end
end

class TagSelector
  OR = -1
  AND = -2
  NOT = -3
  TITLE = -4
  UPLOADER = -5
  SOURCE = -6
  GROUP_START = -7
  GROUP_END = -8
  LENGTH_GT = -9
  LENGTH_LT = -10
  SCORE_GT = -11
  SCORE_LT = -12
  AUDIO_ONLY = -13
  
  def self.ranged?(op)
    return 1.is_a?(op.class) && op < -8 && op >= -12
  end
  
  def initialize(search_terms)
    @opset = TagSelector.loadOPS(search_terms)
    @type = "unknown"
  end
  
  def videoQuery_two(page, limit)
    @type = "video"
    v_query = "SELECT v.* FROM videos v, users WHERE v.hidden = false AND v.duplicate_id = 0 AND v.user_id = users.id"
    groups = self.interpret_opset(@opset)[0]
    if groups.length > 0
      groups = groups.map do |group|
        group.to_video_sql
      end
      v_query << " AND ( " + groups.join(' OR ') + " )"
    end
    v_query << " GROUP BY v.id"
    @main_sql = v_query
    @page = page
    @limit = limit
    return self
  end
  
  def userQuery_two(page, limit)
    @type = "user"
    v_query = "SELECT a.* FROM users a"
    groups = self.interpret_opset(@opset)[0]
    if groups.length > 0
      groups = groups.map do |group|
        group.to_user_sql
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
  
  def interpret_opset(opset)
    groupings = []
    current_group = VideoMatchingGroup.new
    while opset.length > 0
      op = opset.shift
      if op == OR
        if current_group.dirty
          groupings << current_group
        end
        current_group = VideoMatchingGroup.new
      elsif op == AND
        opset = current_group.take_param(@type, opset.shift, opset)
      elsif op == GROUP_START
        child = self.interpret_opset(opset)
        current_group.child(child[0])
        opset = child[1]
      elsif op == GROUP_END
        if current_group.dirty
          groupings << current_group
        end
        return [groupings,opset]
      elsif op == OR && opset[0] == GROUP_START
        opset.shift
        child = self.interpret_opset(opset)
        child[0].negate
        if current_group
          current_group.child(child[0])
        else
          current_group = child[0]
        end
        opset = child[1]
      else
        opset = current_group.take_param(@type, op, opset)
      end
    end
    if current_group.dirty
      groupings << current_group
    end
    return [groupings,opset]
  end
  
  def build_query_string(tag_matcher, not_tag_matcher, title_matcher, name_matcher, not_having_clause, having_clause)
    opset = @opset.clone
    query_string = ''
    having_string = ''
    and_group = []
    while opset.length > 0
      op = opset.shift
      if op == AND
        data = opset.shift
        if data == TITLE || data == UPLOADER || data == NOT
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " AND "
            having_string << self.sanitize([having_clause, and_group, and_group.length.to_s]) + " AND "
            and_group = []
          end
          if data == TITLE
            query_string << self.system_tag_matcher(opset.shift, title_matcher, ' AND ')
          elsif data == UPLOADER
            query_string << self.system_tag_matcher(opset.shift, name_matcher, ' AND ')
          else
            query_string << self.sanitize([not_tag_matcher, opset.shift]) + " AND "
            having_string << self.sanitize([not_having_clause, opset.shift]) + " AND "
          end
        elsif data.length > 0
          and_group << data
        end
      elsif op == OR
        data = opset.shift
        if data == TITLE || data == UPLOADER || data == NOT
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " OR "
            having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
            and_group = []
          end
          if data == TITLE
            query_string << self.system_tag_matcher(opset.shift, title_matcher, ' AND ')
          elsif data == UPLOADER
            query_string << self.system_tag_matcher(opset.shift, name_matcher, ' AND ')
          else
            query_string << self.sanitize([not_tag_matcher, opset.shift]) + " AND "
            having_string << self.sanitize([not_having_clause, opset.shift]) + " AND "
          end
        else
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " OR "
            having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
            and_group = []
          end
          if data.length > 0
            and_group << data
          end
        end
      elsif op == TITLE
        if and_group.length > 0
          query_string << self.sanitize([tag_matcher, and_group]) + " OR "
          having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
          and_group = []
        end
        query_string << self.system_tag_matcher(opset.shift, title_matcher, ' AND ')
      elsif op == UPLOADER
        if and_group.length > 0
          query_string << self.sanitize([tag_matcher, and_group]) + " OR "
          having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
          and_group = []
        end
        query_string << self.system_tag_matcher(opset.shift, name_matcher, ' AND ')
      elsif op == NOT
        if and_group.length > 0
          query_string << self.sanitize([tag_matcher, and_group]) + " OR "
          having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
          and_group = []
        end
        query_string << self.sanitize([not_tag_matcher, opset.shift]) + " OR "
        having_string << self.sanitize([not_having_clause, opset.shift]) + " OR "
      elsif op.length > 0
        and_group << op
      end
    end
    if and_group.length > 0
      query_string << self.sanitize([tag_matcher, and_group]) + " OR "
      having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
      and_group = []
    end
    if query_string.end_with?(' OR ')
      query_string << 'false'
      having_string << 'false'
    else
      query_string << 'true'
      having_string << 'true'
    end
    return [query_string, having_string]
  end
  
  def system_tag_matcher(data, matcher, suffex)
    if matcher
      return self.sanitize([matcher, '%' + data.to_s + '%']) + suffex
    end
    return ""
  end
  
  def self.slurpSystemTags(slurp, opset)
    if slurp.index('title:') == 0
      opset << TITLE
      slurp = slurp.sub(/title\:/,'')
    elsif slurp.index('uploader:') == 0
      opset << UPLOADER
      slurp = slurp.sub(/uploader\:/,'')
    elsif slurp.index('source:') == 0
      opset << SOURCE
      slurp = slurp.sub(/source\:/,'')
    elsif slurp.index('length<') == 0
      opset << LENGTH_LT
      slurp = slurp.sub(/length</,'')
    elsif slurp.index('length>') == 0
      opset << LENGTH_GT
      slurp = slurp.sub(/length>/,'')
    elsif slurp.index('score<') == 0
      opset << SCORE_LT
      slurp = slurp.sub(/score</,'')
    elsif slurp.index('score>') == 0
      opset << SCORE_GT
      slurp = slurp.sub(/score>/,'')
    elsif slurp == 'is:audio'
      opset << AUDIO_ONLY
      slurp = ''
    end
    return slurp
  end
  
  def self.loadOPS(search_terms)
    if !search_terms || search_terms.strip.length == 0
      return []
    end
    opset = []
    slurp = ""
    prev = ""
    open_count = 0
    search_terms.strip.split('').each do |i|
      if i == ' '
        if prev == ',' || prev == '&' || prev == '|'
          prev = i
          next
        end
      end
      if slurp.length > 0
        if i == ',' || (prev == ' ' && i == '&')
          if slurp.index('-') == 0
            slurp = slurp.sub(/-/,'')
            opset << NOT
          end
          opset << TagSelector.slurpSystemTags(slurp, opset)
          slurp = ""
          opset << AND
        elsif prev == ' ' && i == '|'
          if slurp.index('-') == 0
            slurp = slurp.sub(/-/,'')
            opset << NOT
          end
          opset << TagSelector.slurpSystemTags(slurp, opset)
          slurp = ""
          opset << OR
        elsif i == ')' && prev != '\\'
          if open_count > 0
            if slurp.index('-') == 0
              slurp = slurp.sub(/-/,'')
              opset << NOT
            end
            opset << TagSelector.slurpSystemTags(slurp, opset)
            slurp = ""
            opset << GROUP_END
            open_count -= 1
          else
            slurp << i
          end
        else
          slurp << i
        end
      elsif i == '(' && prev != '\\'
        opset << GROUP_START
        open_count += 1
      elsif i == ')' && prev != '\\'
        if open_count > 0
          opset << GROUP_END
          open_count -= 1
        else
          slurp << i
        end
      else
        if i == '-'
          opset << NOT
        else
          slurp << i
        end
      end
      prev = i
    end
    if slurp.length > 0
      slurp = TagSelector.slurpSystemTags(slurp, opset)
      if slurp.index('-') == 0
        slurp = slurp.sub(/-/,'')
        opset << NOT
      end
      opset << slurp
    end
    if open_count != 0
      raise LexerError, "Unmatched '(' for + '" + search_terms + "'!"
    end
    return opset
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
