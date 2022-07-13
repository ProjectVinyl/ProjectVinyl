class VideoChapter < ApplicationRecord
  belongs_to :video

  scope :to_jsons, ->{
    pluck(:title, :timestamp).map{|entry| {title: entry[0], time: entry[1]} }
  }

  def self.extract_title(text)
    (text.strip.split(/[^a-zA-Z0-9 ]/)[0] || '').strip
  end

  def self.read_from_node(node)
    return if node.next.nil? || !node.next.text_node?
    h = extract_title(node.next.inner_text)
    yield title: h, timestamp: node.attributes[:time] if h.length > 0
  end
end
