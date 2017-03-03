require 'projectvinyl/search/lexer_error'
require 'projectvinyl/search/matching_group'

module ProjectVinyl
  module Search
    class Op
      OR = -1
      AND = -2
      NOT = -3
      TITLE = -4
      UPLOADER = -5
      SOURCE = -6
      GROUP_START = -7
      GROUP_END = -8
      AUDIO_ONLY = -9
      LENGTH_GT = -10
      LENGTH_LT = -11
      SCORE_GT = -12
      SCORE_LT = -13
      VOTE_U = -14
      VOTE_D = 15
      
      def self.ranged?(op)
        return 1.is_a?(op.class) && op < -9 && op >= -13
      end
      
      def slurpSystemTags(slurp)
        if slurp.index('title:') == 0
          @opset << slurp.sub(/title\:/,'')
          return Op::TITLE
        elsif slurp.index('name:') == 0
          @opset << slurp.sub(/name\:/,'')
          return Op::TITLE
        elsif slurp.index('uploader:') == 0
          @opset << slurp.sub(/uploader\:/,'')
          return Op::UPLOADER
        elsif slurp.index('source:') == 0
          @opset << slurp.sub(/source\:/,'')
          return Op::SOURCE
        elsif slurp.index('length<') == 0
          @opset << slurp.sub(/length</,'')
          return Op::LENGTH_LT
        elsif slurp.index('length>') == 0
          @opset << slurp.sub(/length>/,'')
          return Op::LENGTH_GT
        elsif slurp.index('score<') == 0
          @opset << slurp.sub(/score</,'')
          return Op::SCORE_LT
        elsif slurp.index('score>') == 0
          @opset << slurp.sub(/score>/,'')
          return Op::SCORE_GT
        elsif slurp == 'is:audio'
          return Op::AUDIO_ONLY
        elsif slurp == 'is:upvoted'
          @opset << 'nil'
          return Op::VOTE_U
        elsif slurp.index('upvoted_by:') == 0
          @opset = slurp.sub(/upvoted_by:/,'')
          return Op::VOTE_U
        elsif slurp == 'is:downvoted'
          @opset << 'nil'
          return Op::VOTE_D
        elsif slurp.index('upvoted_by:') == 0
          @opset << slurp.sub(/upvoted_by:/,'')
          return Op::VOTE_U
        end
        return slurp
      end
      
      def self.loadOPS(search_terms)
        return Op.new(search_terms)
      end
      
      def initialize(search_terms)
        @opset = []
        @open_count = 0;
        @old = []
        if !search_terms || (search_terms = search_terms.strip).length == 0
          @terms = []
        else
          @terms = search_terms.split('')
        end
      end
      
      def length
        @terms.length + @opset.length
      end
      
      def peek(n)
        while @opset.length < n && @terms.length > 0
          @opset << __shift
        end
        result = []
        for i in 0..(n-1)
          if i < @opset.length
            result << @opset[i]
          else
            result << ""
          end
        end
        return result
      end
      
      def shift
        if @opset.length > 0
          return @opset.shift
        end
        return __shift
      end
      
      def __shift
        slurp = ""
        prev = @old.length > 0 ? @old.last : ''
        while @terms.length > 0
          i = @terms.shift
          @old << i
          if i == ' '
            if prev == ',' || prev == '&' || prev == '|'
              prev = i
              next
            end
          end
          if slurp.length > 0
            if i == ',' || (prev == ' ' && i == '&')
              o = slurpSystemTags(slurp)
              @opset << Op::AND
              return o
            elsif prev == ' ' && i == '|'
              o = slurpSystemTags(slurp)
              @opset << Op::OR
              return o
            elsif i == ')' && prev != '\\'
              if @open_count > 0
                @open_count -= 1
                o = slurpSystemTags(slurp)
                @opset << Op::GROUP_END
                return o
              else
                slurp << i
              end
            else
              slurp << i
            end
          elsif i == '(' && prev != '\\'
            @open_count += 1
            return Op::GROUP_START
          elsif i == ')' && prev != '\\'
            if @open_count > 0
              @open_count -= 1
              return Op::GROUP_END
            else
              slurp << i
            end
          else
            if i == '-'
              return Op::NOT
            else
              slurp << i
            end
          end
          prev = i
        end
        if slurp.length > 0
          return slurpSystemTags(slurp)
        end
        if @open_count != 0
          raise LexerError, "Unmatched '(' for + '" + @old + "|" + @terms.join('') + "'!"
        end
        raise "Pointer overrun!"
      end
    end
  end
end