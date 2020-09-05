require 'projectvinyl/bbc/tag_generator'
require 'projectvinyl/bbc/text_node'

module ProjectVinyl
  module Bbc
    class Attributes < Hash
      def initialize
        super do
          ""
        end
      end

      def only(*keys)
        Attributes.new.merge(select {|k,_| keys.include? k })
      end

      def to_html
        entries.map{|entry| " #{entry[0]}=\"#{entry[1]}\""}.join('')
      end
    end
  end
end
