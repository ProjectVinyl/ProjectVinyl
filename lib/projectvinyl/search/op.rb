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
      
      def self.slurpSystemTags(slurp, opset)
        if slurp.index('title:') == 0
          opset << Op::TITLE
          slurp = slurp.sub(/title\:/,'')
        elsif slurp.index('uploader:') == 0
          opset << Op::UPLOADER
          slurp = slurp.sub(/uploader\:/,'')
        elsif slurp.index('source:') == 0
          opset << Op::SOURCE
          slurp = slurp.sub(/source\:/,'')
        elsif slurp.index('length<') == 0
          opset << Op::LENGTH_LT
          slurp = slurp.sub(/length</,'')
        elsif slurp.index('length>') == 0
          opset << Op::LENGTH_GT
          slurp = slurp.sub(/length>/,'')
        elsif slurp.index('score<') == 0
          opset << Op::SCORE_LT
          slurp = slurp.sub(/score</,'')
        elsif slurp.index('score>') == 0
          opset << Op::SCORE_GT
          slurp = slurp.sub(/score>/,'')
        elsif slurp == 'is:audio'
          opset << Op::AUDIO_ONLY
          slurp = ''
        elsif slurp == 'is:upvoted'
          opset << Op::VOTE_U
          slurp = 'nil'
        elsif slurp.index('upvoted_by:') == 0
          opset << Op::VOTE_U
          slurp = slurp.sub(/upvoted_by:/,'')
        elsif slurp == 'is:downvoted'
          opset << Op::VOTE_D
          slurp = 'nil'
        elsif slurp.index('upvoted_by:') == 0
          opset << Op::VOTE_U
          slurp = slurp.sub(/upvoted_by:/,'')
        end
        return slurp
      end
      
      def self.loadOPS(search_terms)
        if !search_terms || search_terms.strip.length == 0
          return []
        end
        opset = []
        slurp = ""
        prev = ""
        open_count = 0
        search_terms.strip.split('').each do |i|
          if i == ' '
            if prev == ',' || prev == '&' || prev == '|'
              prev = i
              next
            end
          end
          if slurp.length > 0
            if i == ',' || (prev == ' ' && i == '&')
              if slurp.index('-') == 0
                slurp = slurp.sub(/-/,'')
                opset << Op::NOT
              end
              opset << Op.slurpSystemTags(slurp, opset)
              slurp = ""
              opset << Op::AND
            elsif prev == ' ' && i == '|'
              if slurp.index('-') == 0
                slurp = slurp.sub(/-/,'')
                opset << Op::NOT
              end
              opset << Op.slurpSystemTags(slurp, opset)
              slurp = ""
              opset << Op::OR
            elsif i == ')' && prev != '\\'
              if open_count > 0
                if slurp.index('-') == 0
                  slurp = slurp.sub(/-/,'')
                  opset << Op::NOT
                end
                opset << Op.slurpSystemTags(slurp, opset)
                slurp = ""
                opset << Op::GROUP_END
                open_count -= 1
              else
                slurp << i
              end
            else
              slurp << i
            end
          elsif i == '(' && prev != '\\'
            opset << Op::GROUP_START
            open_count += 1
          elsif i == ')' && prev != '\\'
            if open_count > 0
              opset << Op::GROUP_END
              open_count -= 1
            else
              slurp << i
            end
          else
            if i == '-'
              opset << Op::NOT
            else
              slurp << i
            end
          end
          prev = i
        end
        if slurp.length > 0
          slurp = Op.slurpSystemTags(slurp, opset)
          if slurp.index('-') == 0
            slurp = slurp.sub(/-/,'')
            opset << Op::NOT
          end
          opset << slurp
        end
        if open_count != 0
          raise LexerError, "Unmatched '(' for + '" + search_terms + "'!"
        end
        return opset
      end
    end
  end
end