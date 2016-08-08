class TagSelector
  OR = -1
  AND = -2
  TITLE = -3
  UPLOADER = -4
  
  def initialize(search_terms)
    @opset = TagSelector.loadOPS(search_terms)
puts @opset
  end
  
  def videoQuery(page, limit)
    if page < 0
      page = 0
    end
    @type = "video"
    query_strings = self.build_query_string()
    v_query = "SELECT v.*, a.name, g.name FROM video_genres t RIGHT JOIN videos v ON t.video_id = v.id, tags g, artists a"
    v_query << " 
WHERE ("
    if query_strings[0].index('g.name IN (').nil?
      v_query << "t.video_id IS NULL OR"
    end
    v_query << " (g.id = t.tag_id AND v.artist_id = a.id)) AND (" + query_strings[0] + ")"
    v_query << " GROUP BY v.id"
    v_query << " HAVING (" + query_strings[1] + ")"
    @main_sql = v_query
    @page = page
    @limit = limit
    return self
  end
  
  def order(type, ordering, ascending)
    @ordering = "v.created_at"
    if type == 0
      if ordering == 1
        @ordering = "v.created_at, v.updated_at"
      elsif ordering == 2
        @ordering = "v.score, v.created_at, v.updated_at"
      elsif ordering == 3
        @ordering = "v.score, v.created_at, v.updated_at"
      end
    end
    if !ascending
      @ordering << " DESC"
    end
    return self
  end
  
  def exec()
    sql = @main_sql + " ORDER BY " + @ordering + " LIMIT " + @limit.to_s + " OFFSET " + (@page * @limit).to_s
    @records = Video.find_by_sql(sql)
    if @records.length == 0 && @page > 0
      @page = @page - 1
      sql = @main_sql + " ORDER BY " + @ordering + " LIMIT " + @limit.to_s + " OFFSET " + (@page * @limit).to_s
      @records = Video.find_by_sql(sql) #ActiveRecord::Base.connection.exec_query
    end
    return self
  end
  
  def build_query_string()
    # tag, tag,tag & tag | tag & title:something, uploader:someone
    # `tags`.name IN ('tag','tag','tag','tag') OR `tags`.name IN ('tag') AND `videos`.title LIKE %something% AND
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
            query_string << "g.name IN ('" + and_group.join("','") + "') AND "
            having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") AND "
            and_group = []
          end
          if data == TITLE
            query_string << "v.title LIKE '%" + opset.shift.to_s + "%' AND "
          else
            query_string << "a.name LIKE '%" + opset.shift.to_s + "%' AND "
          end
        else
          and_group << data
        end
      elsif op == OR
        data = opset.shift
        if data == TITLE || data == UPLOADER
          if and_group.length > 0
            query_string << "g.name IN ('" + and_group.join("','") + "') OR "
            having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") OR "
            and_group = []
          end
          if data == TITLE
            query_string << "v.title LIKE '%" + opset.shift.to_s + "%' AND "
          else
            query_string << "a.name LIKE '%" + opset.shift.to_s + "%' AND "
          end
        else
          if and_group.length > 0
            query_string << "g.name IN ('" + and_group.join("','") + "') OR "
            having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") OR "
            and_group = []
          end
          and_group << data
        end
      elsif op == TITLE
        if and_group.length > 0
          query_string << "g.name IN ('" + and_group.join("','") + "') OR "
          having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") OR "
          and_group = []
        end
        query_string << "v.title LIKE '%" + opset.shift.to_s + "%' AND "
      elsif op == UPLOADER
        if and_group.length > 0
          query_string << "g.name IN ('" + and_group.join("','") + "') OR "
          having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") OR "
          and_group = []
        end
        query_string << "a.name LIKE '%" + opset.shift.to_s + "%' AND "
      else
        and_group << op
      end
    end
    if and_group.length > 0
puts 'Picking up last and group (' + and_group.length.to_s + ')'
      query_string << "g.name IN ('" + and_group.join("','") + "') OR "
      having_string << "(g.name IN ('" + and_group.join("','") + "') AND COUNT(DISTINCT g.name) = " + and_group.length.to_s + ") OR "
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
