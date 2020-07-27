module ProjectVinyl
  module ElasticSearch
    class Op
      OR = -1
      AND = -2
      NOT = -3
      GROUP_START = -4
      GROUP_END = -5
      LESS_THAN = -6
      GREATER_THAN = -7
      EQUAL = -8
      TEXT_EQUAL = -9
      MY = -10

      def self.is?(op)
        1.is_a?(op.class) && op < 0 && op >= HIDDEN
      end

      def self.name_of(op)
        Op.constants.each do |c|
          return c.to_s.downcase.to_sym if Op.const_get(c) == op
        end
        :unknown
      end

      def self.load_ops(search_terms)
        ProjectVinyl::ElasticSearch::Opset.new(search_terms, ProjectVinyl::ElasticSearch::Index::VIDEO_INDEX_PARAMS)
      end
    end
  end
end
