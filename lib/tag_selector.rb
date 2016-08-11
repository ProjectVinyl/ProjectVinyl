class TagSelector
  OR = -1
  AND = -2
  TITLE = -3
  UPLOADER = -4
  
  def initialize(search_terms)
    @opset = TagSelector.loadOPS(search_terms)
  end
  
  def videoQuery(page, limit)
    if page < 0
      page = 0
    end
    @type = "video"
    v_query = "SELECT v.*, a.username, g.name FROM video_genres t RIGHT JOIN videos v ON t.video_id = v.id, users a, tags g"
    query_strings = self.build_query_string("g.name IN (?)",
                                            "v.title LIKE ?",
                                            "a.username LIKE ?",
                                            "(g.name IN (?) AND COUNT(DISTINCT g.name) = ?)")
    v_query << " 
WHERE (v.user_id = a.id AND ("
    if query_strings[0].index('g.name IN (').nil?
      v_query << "t.video_id IS NULL OR "
    end
    v_query << "g.id = t.tag_id)) AND (" + query_strings[0] + ")"
    v_query << " GROUP BY v.id"
    v_query << " HAVING (" + query_strings[1] + ")"
    @main_sql = v_query
    @page = page
    @limit = limit
    return self
  end
  
  def userQuery(page, limit)
    if page < 0
      page = 0
    end
    @type = "user"
    v_query = "SELECT a.*, g.name tag_name FROM artist_genres t RIGHT JOIN users a ON t.user_id = a.id, tags g"
    query_strings = self.build_query_string("g.name IN (?)",
                                            "a.username LIKE ?",
                                            "",
                                            "(g.name IN (?) AND COUNT(DISTINCT g.name) = ?)")
    v_query << " 
WHERE ("
    if query_strings[0].index('g.name IN (').nil?
      v_query << "t.user_id IS NULL OR "
    end
    v_query << "(g.id = t.tag_id)) AND (" + query_strings[0] + ")"
    v_query << " GROUP BY a.id"
    v_query << " HAVING (" + query_strings[1] + ")"
    @main_sql = v_query
    @page = page
    @limit = limit
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
          session[:random_ordering] = "'" + ordering_columns[Random.new(0..ordering_columns.length)] + "','" + ordering_columns[Random.new(0..ordering_columns.length)] + "'"
        end
        @ordering = session[:random_ordering]
      end
    elsif @type == 'user'
      if ordering == 1 || ordering == 2 || ordering == 3
        @ordering = "a.created_at, a.updated_at"
      elsif ordering == 4
        if @page == 0
          ordering_columns = ["v.length","v.created_at","v.updated_at","v.score","v.views","v.description"]
          session[:random_ordering] = "'" + ordering_columns[Random.new(0..ordering_columns.length)] + "','" + ordering_columns[Random.new(0..ordering_columns.length)] + "'"
        end
        @ordering = session[:random_ordering]
      end
    end
    if !ascending
      @ordering << " DESC"
    end
    return self
  end
  
  def exec()
    sql = @main_sql + " ORDER BY " + @ordering + " LIMIT " + @limit.to_s + " OFFSET " + (@page * @limit).to_s
    if @type == 'video'
      @records = Video.find_by_sql(sql)
    else
      @records = User.find_by_sql(sql)
    end
    if @records.length == 0 && @page > 0
      @page = @page - 1
      sql = @main_sql + " ORDER BY " + @ordering + " LIMIT " + @limit.to_s + " OFFSET " + (@page * @limit).to_s
      if @type == 'video'
        @records = Video.find_by_sql(sql) #ActiveRecord::Base.connection.exec_query
      else
        @records = User.find_by_sql(sql)
      end
    end
    return self
  end
  
  def sanitize(arguments)
    return Tag.sanitize_sql(arguments)
  end
  
  def build_query_string(tag_matcher, title_matcher, name_matcher, having_clause)
    opset = @opset.clone
    query_string = ''
    having_string = ''
    and_group = []
    while opset.length > 0
      op = opset.shift
      if op == AND
        data = opset.shift
        if data == TITLE || data == UPLOADER
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " AND "
            having_string << self.sanitize([having_clause, and_group, and_group.length.to_s]) + " AND "
            and_group = []
          end
          if data == TITLE
            query_string << self.system_tag_matcher(opset.shift, title_matcher, ' AND ')
          else
            query_string << self.system_tag_matcher(opset.shift, name_matcher, ' AND ')
          end
        else
          and_group << data
        end
      elsif op == OR
        data = opset.shift
        if data == TITLE || data == UPLOADER
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " OR "
            having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
            and_group = []
          end
          if data == TITLE
            query_string << self.system_tag_matcher(opset.shift, title_matcher, ' AND ')
          else
            query_string << self.system_tag_matcher(opset.shift, name_matcher, ' AND ')
          end
        else
          if and_group.length > 0
            query_string << self.sanitize([tag_matcher, and_group]) + " OR "
            having_string << self.sanitize([having_clause, and_group, and_group.length]) + " OR "
            and_group = []
          end
          and_group << data
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
      else
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
  
  def self.loadOPS(search_terms)
    opset = []
    slurp = ""
    prev = ""
    search_terms.strip.split('').each do |i|
      if i == ' '
        if prev == ',' || prev == '&' || prev == '|'
          prev = i
          next
        end
      end
      if slurp.length > 0
        if i == ',' || (prev == ' ' && i == '&')
          if slurp.index('title:') == 0
            opset << TITLE
            slurp = slurp.sub(/title\:/,'')
          elsif slurp.index('uploader:') == 0
            opset << UPLOADER
            slurp = slurp.sub(/uploader\:/,'')
          end
          opset << slurp
          slurp = ""
          opset << AND
        elsif prev == ' ' && i == '|'
          if slurp.index('title:') == 0
            opset << TITLE
            slurp = slurp.sub(/title\:/,'')
          elsif slurp.index('uploader:') == 0
            opset << UPLOADER
            slurp = slurp.sub(/uploader\:/,'')
          end
          opset << slurp
          slurp = ""
          opset << OR
        else
          slurp << i
        end
      else
        slurp << i
      end
      prev = i
    end
    if slurp.length
      if slurp.index('title:') == 0
        opset << TITLE
        slurp = slurp.sub(/title\:/,'')
      elsif slurp.index('uploader:') == 0
        opset << UPLOADER
        slurp = slurp.sub(/uploader\:/,'')
      end
      opset << slurp
    end
    return opset
  end
  
  def records
    @records
  end
  
  def page
    @page
  end
  
  def pages
    (@page + @records.length / @limit)
  end
end
