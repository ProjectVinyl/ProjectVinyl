module ProjectVinyl
  module Search
    module Parser
      class VoteQuery
        def initialize(owner)
          @cache = owner.root.user_cache
          @dirty = false
          @lookup = {}
        end

        attr_reader :dirty

        def record(op, opset, sender)
          field = opset.shift_data(op, 'field')
          user = @cache.read_user_id(opset, op, 'user', sender)

          @lookup[field] = [] if !@lookup.key?(field)
          @lookup[field] << user
          @dirty = true
        end

        def compile(dest)
          @lookup.keys.each do |field|
            dest |= @lookup[field].uniq
              .map {|user| @cache.id_for(user)}
              .filter {|id| id}
              .map {|id| { term: { field => id } } }
          end

          dest
        end
      end
    end
  end
end
