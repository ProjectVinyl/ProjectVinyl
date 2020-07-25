require 'projectvinyl/elasticsearch/lexer_error'

module ProjectVinyl
  module ElasticSearch
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
      VOTE_U = -11
      VOTE_D = -12
      ASPECT = -13

      LENGTH_GT = -113
      LENGTH_LT = -114

      SCORE_GT = -115
      SCORE_LT = -116

      CREATED_GT = -117
      CREATED_LT = -118

      WIDTH_GT = -119
      WIDTH_LT = -120

      HEIGHT_GT = -121
      HEIGHT_LT = -122

      SIZE_GT = -123
      SIZE_LT = -124

      GT_TAGS = [ LENGTH_GT, WIDTH_GT, HEIGHT_GT, SCORE_GT, SIZE_GT ]
      FIELD_TAGS = {
        'title:': TITLE,
        'name:': TITLE,
        'uploader:': UPLOADER,
        'source:': SOURCE,
        'aspect:': ASPECT,
        'length<': LENGTH_LT, 'length>': LENGTH_GT,
        'width<': WIDTH_LT, 'width>': WIDTH_GT,
        'height<': HEIGHT_LT, 'height>': HEIGHT_GT,
        'score<': SCORE_LT, 'score>': SCORE_GT,
        'size<': SIZE_LT, 'size>': SIZE_GT,
        'upvoted_by:': VOTE_U,
        'downvoted_by:': VOTE_D
      }.freeze
      CATEGORY_TAGS = {
        'is:audio': AUDIO_ONLY,
        'is:hidden': HIDDEN
      }.freeze
      USER_TAGS = {
        'my:upvotes': VOTE_U,
        'my:downvotes': VOTE_D,
        'my:uploads': UPLOADER
      }.freeze

      def self.is?(op)
        1.is_a?(op.class) && op < 0 && (op >= ASPECT || (op <= LENGTH_GT && op >= SIZE_LT))
      end

      def self.ranged?(op)
        Op.is?(op) && op <= LENGTH_GT
      end

      def self.primitive?(op)
        Op.is?(op) && (op == AUDIO_ONLY || op == HIDDEN)
      end

      def self.ranged_gt?(op)
        GT_TAGS.include?(op)
      end

      def self.name_of(op)
        Op.constants.each do |c|
          return c.to_s.downcase.to_sym if Op.const_get(c) == op
        end
        :unknown
      end

      def slurp_system_tags(slurp)
        slurp = slurp.strip

        if (tag = FIELD_TAGS.keys.find {|key| slurp.index(key.to_s) == 0})
          @opset << slurp.sub(tag.to_s, '')
          return FIELD_TAGS[tag]
        end
        if (tag = CATEGORY_TAGS.keys.find {|key| slurp.index(key.to_s) == 0})
          return CATEGORY_TAGS[tag]
        end
        if (tag = USER_TAGS.keys.find {|key| slurp.index(key.to_s) == 0})
          @opset << 'nil'
          return USER_TAGS[tag]
        end

        slurp
      end

      def self.load_ops(search_terms)
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

      def slurp_quoted_text(quote_char, slurp)
        until @terms.empty?
          i = @terms.shift

          if i == quote_char
            return slurp
          end

          slurp += i
        end

        slurp
      end

      def __shift
        slurp = ""
        prev = !@old.empty? ? @old.last : ''
        until @terms.empty?
          i = @terms.shift
          @old << i

          if i == '"' || i == '\''
            slurp = slurp_quoted_text(i, slurp)
          else
            if i == ' '
              # consume spaces around operators
              if prev == ',' || prev == '&' || prev == '|'
                prev = i
                next
              end
            end

            if !slurp.empty?
              if i == ',' || (prev == ' ' && i == '&')
                o = slurp_system_tags(slurp)
                @opset << Op::AND
                return o
              elsif prev == ' ' && i == '|'
                o = slurp_system_tags(slurp)
                @opset << Op::OR
                return o
              elsif i == ')' && prev != '\\'
                if @open_count > 0
                  @open_count -= 1
                  o = slurp_system_tags(slurp)
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
          end

          prev = i
        end

        return slurp_system_tags(slurp) if !slurp.empty?

        if @open_count != 0
          raise LexerError, "Unmatched '(' for + '" + @old + "|" + @terms.join('') + "'!"
        end

        raise "Pointer overrun!"
      end
    end
  end
end
