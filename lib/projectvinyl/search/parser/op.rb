module ProjectVinyl
  module Search
    module Parser
      class Op
        OR = :or
        AND = :and
        NOT = :not
        GROUP_START = :group_start
        GROUP_END = :group_end
        LESS_THAN = :less_than
        GREATER_THAN = :greater_than
        EQUAL = :equals
        HAS = :has
        TEXT_EQUAL = :text_equals
        MY = :my

        CHAR_OP_LOOKUP = {
          ':': EQUAL,
          '>': GREATER_THAN,
          '<': LESS_THAN
        }.freeze
        
        def self.name_of(op)
          return op if constants.find {|c| Op.const_get(c) == op}
          :unknown
        end
      end
    end
  end
end
