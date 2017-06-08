require 'projectvinyl/search/lexer_error'

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
      HIDDEN = -10
      LENGTH_GT = -11
      LENGTH_LT = -12
      SCORE_GT = -13
      SCORE_LT = -14
      VOTE_U = -15
      VOTE_D = -16

      def self.is?(op)
        1.is_a?(op.class) && op < 0 && op >= Op::VOTE_D
      end

      def self.ranged?(op)
        Op.is?(op) && op <= Op::LENGTH_GT && op >= Op::SCORE_LT
      end

      def self.primitive?(op)
        Op.is?(op) && (op == Op::AUDIO_ONLY || op == Op::HIDDEN)
      end

      def self.name_of(op)
        Op.constants.each do |c|
          return c.to_s.downcase.to_sym if Op.const_get(c) == op
        end
        :unknown
      end

      def slurpSystemTags(slurp)
        slurp = slurp.strip
        if slurp.index('title:') == 0
          @opset << slurp.sub(/title\:/, '')
          return Op::TITLE
        elsif slurp.index('name:') == 0
          @opset << slurp.sub(/name\:/, '')
          return Op::TITLE
        elsif slurp.index('uploader:') == 0
          @opset << slurp.sub(/uploader\:/, '')
          return Op::UPLOADER
        elsif slurp.index('source:') == 0
          @opset << slurp.sub(/source\:/, '')
          return Op::SOURCE
        elsif slurp.index('length<') == 0
          @opset << slurp.sub(/length</, '')
          return Op::LENGTH_LT
        elsif slurp.index('length>') == 0
          @opset << slurp.sub(/length>/, '')
          return Op::LENGTH_GT
        elsif slurp.index('score<') == 0
          @opset << slurp.sub(/score</, '')
          return Op::SCORE_LT
        elsif slurp.index('score>') == 0
          @opset << slurp.sub(/score>/, '')
          return Op::SCORE_GT
        elsif slurp == 'is:audio'
          return Op::AUDIO_ONLY
        elsif slurp == 'is:hidden'
          return Op::HIDDEN
        elsif slurp == 'is:upvoted'
          @opset << 'nil'
          return Op::VOTE_U
        elsif slurp.index('upvoted_by:') == 0
          @opset << slurp.sub(/upvoted_by:/, '')
          return Op::VOTE_U
        elsif slurp == 'is:downvoted'
          @opset << 'nil'
          return Op::VOTE_D
        elsif slurp.index('downvoted_by:') == 0
          @opset << slurp.sub(/downvoted_by:/, '')
          return Op::VOTE_D
        end
        slurp
      end

      def self.loadOPS(search_terms)
        Op.new(search_terms)
      end

      def initialize(search_terms)
        @opset = []
        @open_count = 0
        @old = []
        if !search_terms || (search_terms = search_terms.strip).empty?
          @terms = []
        else
          @terms = search_terms.split('')
        end
      end

      def length
        @terms.length + @opset.length
      end

      def peek(n)
        while @opset.length < n && !@terms.empty?
          stack = @opset
          @opset = []
          stack << __shift
          @opset.each do |i|
            stack << i
          end
          @opset = stack
        end
        result = []
        for i in 0..(n - 1)
          if i < @opset.length
            result << @opset[i]
          else
            result << ""
          end
        end
        result
      end

      def shift
        return @opset.shift if !@opset.empty?
        __shift
      end

      def __shift
        slurp = ""
        prev = !@old.empty? ? @old.last : ''
        until @terms.empty?
          i = @terms.shift
          @old << i
          if i == ' '
            if prev == ',' || prev == '&' || prev == '|'
              prev = i
              next
            end
          end
          if !slurp.empty?
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
        return slurpSystemTags(slurp) if !slurp.empty?
        if @open_count != 0
          raise LexerError, "Unmatched '(' for + '" + @old + "|" + @terms.join('') + "'!"
        end
        raise "Pointer overrun!"
      end
    end
  end
end
