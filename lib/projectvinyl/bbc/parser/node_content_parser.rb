require 'projectvinyl/bbc/emoticons'
require 'projectvinyl/bbc/parser/helpers'

module ProjectVinyl
  module Bbc
    module Parser
      module NodeContentParser
        def self.parse(node, content, text, index, open, close)
          # Convert line breaks to <br> tags
          return ['', parse_line_break(node, content[index..content.length], text)] if Helpers.at_line_break?(content, index)
          return ['', parse_url(node, content[index..content.length], text, open, close)] if !node.handles_urls? && Helpers.head_matches_any?(content, index, ['https:', 'http:'])
          return ['', parse_reply_tag(node, content[index..content.length], text)] if Helpers.head_matches_any?(content, index, ['&gt;&gt;', '>>'])

          if (index == 0 || content[index - 1].strip == '' || content[index - 1] == close)
            return ['', parse_mention(node, content[(index + 1)..content.length], text)] if content[index] == '@'

            if content[index] == ':'
              emote_handled = try_parse_emoticon(node, content[index..content.length], text)
              return ['', emote_handled] if emote_handled != false
            end

            timestamp_handled = try_parse_timestamp(node, content[index..content.length], text)

            return ['', timestamp_handled] if timestamp_handled != false
          end

          return [text, false]
        end

        private
        def self.parse_line_break(node, content, text)
          node.append_text(text).append_node('br')
          content.gsub(/^[\r\n]+/, '')
        end

        def self.parse_mention(node, content, text)
          mention = content.split(/[\s\[\<]/)[0]
          node.append_text(text).append_node('at').append_text(mention)
          content.sub(mention, '')
        end

        def self.parse_reply_tag(node, content, text)
          content = content.sub(/&gt;&gt;|>>/,'')
          reply_tag = content.split(/[^a-z0-9A-Z]/)[0]
          node.append_text(text).append_node('reply').append_text(reply_tag)
          content.sub(reply_tag, '')
        end

        def self.parse_url(node, content, text, open, close)
          url = content.split(open)[0].split(close)[0].split(' ')[0].split('\n')[0].split('\r')[0]
          node.append_text(text)
            .append_node('a')
            .set_attribute('href', url)
            .append_text(TextNode.truncate_link(url))
          content.sub(url, '')
        end

        def self.try_parse_timestamp(node, content, text)
          timestamp = content.split(/[^0-9:]/)[0]
          return false if !timestamp || content.index(timestamp) != 0 || timestamp.index(':') != 2

          node.append_text(text)
            .append_node('timestamp')
            .set_attribute('time', Ffmpeg.from_h_m_s(timestamp))
            .append_text(timestamp)
          content.sub(timestamp, '')
        end

        def self.try_parse_emoticon(node, content, text)
          emote = content.split(':')
          return false if emote.length < 2

          emote = emote[1]
          return false if !Emoticons.is_defined_emote(emote)

          node.append_text(text)
            .append_node('emote')
            .append_text(emote)
          content.sub(':' + emote + ':', '')
        end
      end
    end
  end
end
