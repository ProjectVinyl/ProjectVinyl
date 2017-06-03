require 'net/http'

class Ajax
  def self.get(url, params = {})
    return Ajax.new(url).get(params) do |body|
      yield(body)
    end
  end
  
  def self.post(url, params = {})
    return Ajax.new(url).post(params) do |body|
      yield(body)
    end
  end
  
  def initialize(url)
    @url = URI.parse(url)
    @params = {}
    if url.index('?')
      url = url.split('?')[1].split('&').each do |i|
        i = i.split('=')
        @params[i[0]] = i[1]
      end
    end
  end
  
  def request()
    res = Net::HTTP.start(@url.host, @url.port,
      :use_ssl => @url.scheme == 'https',
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) {|connection|
      connection.request(@req)
    }
    if res.code == '200'
      yield(res.body)
      return true
    end
    return false
  end
  
  def get(params = {})
    @url.query = URI.encode_www_form(@params.merge(params))
    @req = Net::HTTP::Get.new(@url)
    return self.request() do |body|
      yield(body)
    end
  end
  
  def post(params = {})
    @req = Net::HTTP::Post.new(@url)
    @req.set_form_data(@params.merge(params))
    return self.request() do |body|
      yield(body)
    end
  end
end
Ajax.get('https://www.fimfiction.net/user/Sollace') {|body| @body = body }



class TextNode
  def initialize(text)
    @innerHTML = text
  end
  
  def innerHTML
    @innerHTML
  end
  
  def innerText
    @innerHTML
  end
  
  def innerText=(text)
    @innerHTML = text
  end
  
  def id
    ""
  end
  
  def classes
    []
  end
  
  def attributes
    {}
  end
  
  def children
    classes
  end
  
  def getElementById(d)
    nil
  end
  
  def getElementsByTagName(tagName)
    []
  end
  
  def getElementsByClassName(className)
    []
  end
  
  def to_s
    @innerHTML
  end
  
  def to_bbc
    @innerHTML
  end
end

class HTMNode
  def self.Parse(content)
    result = HTMNode.new
    content = result.parse(content)
    if content && content.length > 0
      result.children << TextNode.new(content)
    end
    return result
  end
  
  def self.extract_uri_parameter(url, parameter)
    return URI.unescape(url.split("#{parameter}=").last.split('&').first)
  end
  
  def initialize()
    @attributes = {}
    @children = []
  end
  
  def tagName
    @tagName
  end
  
  def id
    @attributes[:id] || ""
  end  
  
  def classes
    (@attributes[:class] || "").split(' ')
  end
  
  def children
    @children
  end
  
  def attributes
    @attributes
  end
  
  def innerHTML
    result = ''
    @children.each do |i|
      result << i.to_s
    end
    return result
  end
  
  def innerBBC
    result = ''
    @children.each do |i|
      result << i.to_bbc
    end
    return result
  end
  
  def innerText
    if @tagName == 'br'
      return '\n'
    end
    result = ''
    @children.each do |i|
      result << i.innerText
    end
    return result
  end
  
  def innerText=(text)
    @children = []
    @children << TextNode.new(text)
  end
  
  def getElementById(d)
    if self.id == d
      return self
    end
    @children.each do |i|
      result = i.getElementById(d)
      if result
        return result
      end
    end
    return nil
  end
  
  def getElementsByTagName(tagName)
    results = []
    if tagName == @tagName
      results << self
    end
    @children.each do |i|
      results = results + i.getElementsByTagName(tagName)
    end
    return results
  end
  
  def getElementsByClassName(className)
    result = []
    if classes.index(className)
      result << self
    end
    @children.each do |i|
      result = result + i.getElementsByClassName(className)
    end
    return result
  end
  
  def loadAttr(content)
    index = -1
    quote = nil
    name = ''
    value = ''
    inValue = false
    while index < content.length - 1
      index += 1
      if !inValue || quote == nil
        if content[index] == '/' && index < content.length - 1 && content[index + 1] == '>'
          return content[index..content.length]
        end
        if content[index] == '>'
          if name.length > 0
            @attributes[name.strip] = value
          end
          return content[(index+1)..content.length]
        end
      end
      if !inValue
        if content[index] == '='
          inValue = true
          next
        end
        name += content[index]
      else
        if quote == nil
          if content[index] == '"' || content[index] == "'"
            quote = content[index]
            next
          elsif content[index] == ' '
            @attributes[name.strip] = value
            name = ''
            value = ''
            inValue = false
            next
          end
        else
          if content[index] == quote
            quote = nil
            @attributes[name.strip] = value
            name = ''
            value = ''
            inValue = false
            next
          end
        end
        value += content[index]
      end
    end
    return content[(index+1)..content.length]
  end
  
  def parse(content)
    index = -1
    inNode = false
    inContent = false
    tagName = ''
    text = ''
    while index < content.length - 1
      index += 1
      if inContent
        if @tagName == 'br' || @tagName == 'img'
          if content[index] == '/'
            index += 1
          end
          if content[index] == '>'
            index += 1
          end
          return content[index..content.length]
        end
        if content.index('/>') == 0
          return content[3..content.length]
        end
        if content.index('</' + @tagName + '>') == index
          if text.length > 0
            @children << TextNode.new(text)
          end
          return content[(index + ('</' + @tagName + '>').length)..content.length]
        end
        if content.index('<') == index
          if text.length > 0
            @children << TextNode.new(text)
            text = ''
          end
          child = HTMNode.new
          content = child.parse(content)
          @children << child
          index = -1
          next
        end
        text += content[index]
      end
      if inNode
        if content[index] == ' '
          @tagName = tagName.strip
          content = self.loadAttr(content[(index + 1)..content.length])
          index = -1
          inNode = false
          inContent = true
          next
        elsif content[index] == '>' || content[index] == '/'
          if tagName.length == 0
            next
          end
          @tagName = tagName
          inContent = true
          inNode = false
          content = content[(index + 1)..content.length]
          index = -1
          next
        else
          tagName += content[index]
          next
        end
      end
      if content[index] == '<'
        inNode = true
        next
      end
    end
    if text.length > 0
      @children << TextNode.new(text)
    end
    return content[(index+1)..content.length]
  end
  
  def to_s
    "<" + @tagName + " " + @attributes.to_s + ">" + self.innerHTML + "</" + @tagName + ">"
  end
  
  def to_bbc
    if @tagName == 'br'
      return "\n"
    end
    if @tagName == 'a'
      return "[url=" + @attributes['href'] + "]" + self.innerBBC + "[/url]"
    end
    if @tagName == 'img'
      return "[img]" + @attributes['src'] + "[/img]"
    end
    tagName = @tagName
    if tagName == 'blockquote'
      tagName = 'q'
    end
    return "[" + tagName + "]" + self.innerBBC + "[/" + tagName + "]"
  end
end