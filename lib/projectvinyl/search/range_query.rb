module ProjectVinyl
  module Search
    class RangeQuery
      def initialize(op, opset, invert)
        @greater_than = op == Op::LENGTH_GT || op == Op::SCORE_GT
        if invert
          @greater_than = !@greater_than
        end
        @field = op == Op::LENGTH_GT || op == Op::LENGTH_LT ? 'length' : 'score'
        if !(@value = opset.shift) || @value.length == 0
          @value = 0
        else
          if @field == 'length'
            @value = Ffmpeg.from_h_m_s(@value)
          else
            @value = @value.to_i
          end
        end
      end
      
      def to_sql
        Tag.sanitize_sql([@field + (@greater_than ? ' > ?' : ' < ?'), @value])
      end
    end
  end
end