require 'projectvinyl/bbc/node_parser'
require 'projectvinyl/bbc/emoticons'

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
          next ":#{tag.attributes[:data_emote]}:"
        end
        if tag.attributes[:class] && tag.attributes[:class].index('fa fa-fw fa-')
          next "[icon]#{tag.attributes[:class].sub('fa fa-fw fa-', '').split(/[^a-zA-Z0-9]/)[0]}[/icon]"
        end
        "[#{tag.tag_name}]#{tag.inner_bbc}[/#{tag.tag_name}]"
      end
      TagGenerator.register(:bbc, [:blockquote]) do |tag|
        "[q]#{tag.inner_bbc}[/q]"
      end
      TagGenerator.register(:bbc, [:at]) do |tag|
        "@#{tag.inner_text}"
      end
      TagGenerator.register(:bbc, [:reply]) do |tag|
        ">>#{tag.inner_text}"
      end
      TagGenerator.register(:bbc, [:a]) do |tag|
        if !tag.attributes[:href]
          next tag.inner_bbc
        end
        
        if tag.classes.include?('user-link')
          next "@#{tag.inner_text}"
        end
        
        if tag.attributes[:data_link]
          if tag.attributes[:data_link] == '1'
            next tag.attributes[:href]
          end
          if tag.attributes[:data_link] == '2'
            next ">>#{tag.attributes[:href].sub('#comment_', '')}"
          end
        end
        
        "[url=#{tag.attributes[:href]}]#{tag.inner_bbc}[/url]"
      end
      TagGenerator.register(:bbc, [:div]) do |tag|
        if tag.classes.include?('spoiler')
          next "[spoiler]#{tag.inner_bbc}[/spoiler]"
        end
        tag.inner_bbc
      end
      TagGenerator.register(:bbc, [:img]) do |tag|
        "[img]#{tag.attributes[:src]}[img]#{tag.inner_bbc}"
      end
      TagGenerator.register(:bbc, [:emote]) do |tag|
        ":#{tag.inner_text}:"
      end
      TagGenerator.register(:bbc, [:iframe]) do |tag|
        if tag.attributes[:scr] && tag.attributes[:class] == 'embed'
          if Youtube.is_video_link(tag.attributes[:src])
            next "[yt#{Youtube.video_id(tag.attributes[:src])}]#{tag.inner_bbc}"
          end
          next "[#{tag.attributes[:src].gsub(/[^0-9]/,'')}]#{tag.inner_bbc}"
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
        "<a href=\"#{tag.equals_par  || tag.inner_text}\">#{tag.inner_html}</a>"
      end
      TagGenerator.register(:html, [:a]) do |tag|
        "<#{tag.tag_name} href=\"#{tag.attributes[:href]}\">#{tag.inner_html}</#{tag.tag_name}>"
      end
      TagGenerator.register(:html, [:br]) do |tag|
        "<#{tag.tag_name} />#{tag.inner_html}"
      end
      TagGenerator.register(:html, [:at]) do |tag|
        tag.resolve_dynamically do
          "<a class=\"user-link\" data-id=\"0\">#{tag.inner_text}</a>"
        end
      end
      TagGenerator.register(:html, [:reply]) do |tag|
        tag.resolve_dynamically do
          "<a data-link=\"2\" href=\"#comment_#{tag.inner_text}\">#{tag.inner_text}</a>"
        end
      end
      TagGenerator.register(:html, [:spoiler]) do |tag|
        "<div class=\"spoiler\">#{tag.inner_html}</div>"
      end
      TagGenerator.register(:html, [:img]) do |tag|
        "<img src=\"#{tag.inner_text.gsub(/['"]/,'')}\"></img>"
      end
      TagGenerator.register(:html, [:emote]) do |tag|
        Emoticons.emoticon_tag(tag.inner_text)
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