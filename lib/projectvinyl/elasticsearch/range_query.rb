require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class RangeQuery
      def initialize
        @ranges = {}
        @dirty = false
      end

      def record(op, opset, invert)
        greater_than = is_gt(op)
        field = field_for(op)

        if !(value = opset.shift) || value.empty?
          @value = 0
        else
          if field == :length
            value = Ffmpeg.from_h_m_s(value)
          else
            value = value.to_i
          end
        end

        @ranges[field] = {} if !@ranges.key?(field)
        @ranges[field][invert ? (greater_than ? :lte : :gte) : (greater_than ? :gt : :lt)] = value
        @dirty = true
      end

      def field_for(op)
        if op == Op::LENGTH_GT || op == Op::LENGTH_LT
          return :length
        end
        if op == Op::SCORE_GT || op == Op::SCORE_LT
          return :score
        end
        puts op
        raise "Bad OP"
      end

      def is_gt(op)
        op == Op::LENGTH_GT || op == Op::SCORE_GT
      end

      def to_sql
        Tag.sanitize_sql([@field + (@greater_than ? ' > ?' : ' < ?'), @value])
      end

      attr_reader :dirty

      def to_hash
        { range: @ranges }
      end
    end
  end
end
