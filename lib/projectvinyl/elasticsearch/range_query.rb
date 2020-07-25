require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class RangeQuery
      def initialize
        @ranges = {}
        @dirty = false
      end

      attr_reader :dirty

      def record(op, opset, invert)
        greater_than = is_gt(op)
        field = field_for(op)

        if !(value = opset.shift) || value.empty?
          @value = 0
        else
          if field == :length
            value = Ffmpeg.from_h_m_s(value)
          elsif field == :created_at || field == :updated_at
            value = DateTime.parse(value)
          else
            value = value.to_i
          end
        end

        @ranges[field] = {} if !@ranges.key?(field)
        @ranges[field][invert ? (greater_than ? :lte : :gte) : (greater_than ? :gt : :lt)] = value
        @dirty = true
      end

      def field_for(op)
        return :length if op == Op::LENGTH_GT || op == Op::LENGTH_LT
        return :score if op == Op::SCORE_GT || op == Op::SCORE_LT
        return :created_at if op == Op::CREATED_GT || op == Op::CREATED_LT
        return :width if op == Op::WIDTH_GT || op == Op::WIDTH_LT
        return :height if op == Op::HEIGHT_GT || op == Op::HEIGHT_LT
        return :file_size if op == Op::SIZE_GT || op == Op::SIZE_LT
        raise "Bad OP: " + op
      end

      def is_gt(op)
        Op.ranged_qt?(op)
      end

      def to_sql
        Tag.sanitize_sql([@field + (@greater_than ? ' > ?' : ' < ?'), @value])
      end

      def to_hash
        { range: @ranges }
      end
    end
  end
end
