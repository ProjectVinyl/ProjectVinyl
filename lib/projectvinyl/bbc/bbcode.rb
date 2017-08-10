require 'projectvinyl/bbc/node_parser'

module ProjectVinyl
  module Bbc
    class Bbcode
      TagGenerator.register(:bbc, [:br]) do |tag|
        "\n#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:hr]) do |tag|
        "[hr]#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:b,:u,:s,:sup,:sub,:spoiler]) do |tag|
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:i]) do |tag|
        if tag.classes.include?('emote')
          return ":#{tag.attributes[:data_emote]}:"
        end
        if tag.attributes[:class] && tag.attributes[:class].index('fa fa-fw fa-')
          return "[icon]#{tag.attributes[:class].sub('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0]}[/icon]"
        end
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:blockquote]) do |tag|
        "[q]#{tag.inner_bbc}[/q]"
      end
      TagGenerator.register(:bbc, [:at]) do |tag|
        "@#{tag.inner_text}"
      end
      TagGenerator.register(:html, [:reply]) do |tag|
        "&gt;&gt#{tag.inner_text}"
      end
      TagGenerator.register(:bbc, [:a]) do |tag|
        if !tag.attributes[:href]
          return tag.inner_bbc
        end
        
        if tag.classes.includes?('user-link')
          return "@#{tag.inner_text}"
        end
        
        if tag.attributes[:data_link]
          if tag.attributes[:data_link] == '1'
            return tag.attributes[:href]
          end
          if tag.attributes[:data_link] == '2'
            return "&gt;&gt#{tag.attributes[:href].sub('#comment_', '')}"
          end
        end
        
        "[url=#{tag.attributes[:href]}]#{tag.inner_bbc}[/url]"
      end
      TagGenerator.register(:bbc, [:div]) do |tag|
        if tag.classes.include?('spoiler')
          return "[spoiler]#{tag.inner_bbc}[/spoiler]"
        end
        tag.inner_bbc
      end
      TagGenerator.register(:bbc, [:img]) do |tag|
        "[img]#{tag.attributes[:src]}[img]#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:emote]) do |tag|
        return ":#{tag.inner_text}:"
      end
      TagGenerator.register(:bbc, [:iframe]) do |tag|
        if tag.attributes[:scr] && tag.attributes[:class] == 'embed'
          if Youtube.is_video_link(tag.attributes[:src])
            return "[yt#{Youtube.video_id(tag.attributes[:src])}]#{tag.inner_bbc}"
          end
          return "[#{tag.attributes[:src].gsub(/[^0-9]/,'')}]#{tag.inner_bbc}"
        end
        tag.inner_bbc
      end
      
      TagGenerator.register(:html, [:b,:i,:u,:s,:sup,:sub,:hr]) do |tag|
        "<#{tag.tag_name}>#{tag.inner_html}</#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:icon]) do |tag|
        "<i class=\"fa fa-fw fa-#{tag.inner_text.split(/[^a-zA-Z0-9]/)[0]}\"></#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:q]) do |tag|
        "<blockquote#{!tag.even ? ' class="even"' : ''}>#{tag.inner_html}</blockquote>"
      end
      TagGenerator.register(:html, [:url]) do |tag|
        "<a href=\"#{tag.equals_par  || tag.inner_text}\">#{tag.inner_html}</a>}"
      end
      TagGenerator.register(:html, [:reply]) do |tag|
        "<a data-link=\"2\" href=\"#comment_#{tag.inner_text}\">&gt;&gt;#{tag.inner_text}</a>"
      end
      TagGenerator.register(:html, [:spoiler]) do |tag|
        "<div class=\"spoiler\">#{tag.inner_html}</div>"
      end
      TagGenerator.register(:html, [:img]) do |tag|
        "<img src=\"#{tag.inner_text.gsub(/['"]/,'')}\"></img>"
      end
      TagGenerator.register(:html, [:emote]) do |tag|
        "<i class=\"emote\" data-emote=\"#{tag.inner_text}\">:#{tag.inner_text}:</i>"
      end
      
      def self.from_html(html)
        NodeParser.parse(html, '<', '>')
      end
      
      def self.from_bbc(bbc)
        NodeParser.parse(bbc, '[', ']')
      end
    end
  end
end