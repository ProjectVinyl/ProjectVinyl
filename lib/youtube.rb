class Youtube
  def self.get(url)
    result = {}
    oembed_url = 
    Ajax.get('https://www.youtube.com/oembed', url: 'http:' + url.sub(/http?(s):/, ''), format: 'json') do |body|
      body = JSON.parse(body)
      result[:title] = body['title']
      result[:artist] = body['author_name']
    end
    Ajax.get(url) do |body|
      if desk = Youtube.description_from_html(body)
        desc_node = HTMNode.Parse("<div>" + desk + "</div>")
        desc_node.getElementsByTagName('a').each do |a|
          a.innerText = a.attributes['href']
        end
        result[:description] = {
          html: desc_node.innerHTML,
          bbc: desc_node.innerBBC
        }
      end
    end
    return result
  end
  
  def self.description_from_html(html)
    description_index = html.index('id="eow-description"')
    if !description_index
      return nil
    end
    html = html[description_index..html.length]
    html = html.split('</p>')[0].split('>')
    html.shift
    return html.join('>')
  end
  
  def self.is_video_link(url)
    if url.nil? || (url = url.strip).length == 0
      return false
    end
    return !(url =~ /http?(s):\/\/(www\.|m\.)(youtube\.[^\/]+\/watch\?.*v=|youtu\.be\/)([^&]+)/).nil?
  end
  
  def self.video_id(url)
    if url.index('v=')
      return url.split('v=')[1].split('&')[0]
    end
    return url.split('?')[0].split('/').last
  end
end