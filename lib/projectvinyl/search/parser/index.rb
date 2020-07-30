require 'projectvinyl/search/parser/op'

module ProjectVinyl
  module Search
    module Parser
      class Index
        attr_reader :table

        def initialize(table, params = {}, &block)
          @table = table
          @params = params
          @default_func = block
        end

        def slurp_tags(opset, slurp)
          slurp = slurp.strip

          if @params.key?(:hash) && slurp[0] == '#'
            opset.push @params[:hash]
            opset.push slurp[1..slurp.length]
            return Op::HAS
          end

          slugs = slurp.split(/[<>:]/)

          return fallback(opset, slurp) if slugs.length < 2

          prefix = slugs[0]
          separator = slurp[prefix.length...(prefix.length + 1)].to_sym
          suffex = slurp[(prefix.length + 1)...slurp.length].strip

          prefix = prefix.to_sym

          # Self-based tags
          return Op::MY if check_pre(opset, :my, prefix, suffex, nil)
          # Boolean set operators
          return Op::EQUAL if check_pre(opset, :is, prefix, suffex, true)
          # User-based tags
          return Op::MY if check_post(opset, :by, prefix, suffex)
          # Greater than, less than, or equals
          return Op::CHAR_OP_LOOKUP[separator] if check_post(opset, :range_fields, prefix, suffex)
          # Tag-based queries
          return Op::HAS if check_post(opset, :has, prefix, suffex)
          # Only equals
          return Op::TEXT_EQUAL if check_post(opset, :fields, prefix, suffex)

          fallback(opset, slurp)
        end

        def fallback(opset, slugs)
          return @default_func.call(self, opset, slugs) if @default_func
          opset.push :tags
          opset.push slugs
          Op::HAS
        end

        def check_pre(opset, group, prefix, suffex, value)
          suffex = suffex.to_sym
          if prefix == group && @params.key?(group) && @params[group].key?(suffex)
            opset.push @params[group][suffex] # the field to check
            opset.push value                  # the value
            true
          end
        end

        def check_post(opset, group, prefix, suffex)
          if @params.key?(group) && @params[group].key?(prefix)
            opset.push @params[group][prefix] # the field to check
            opset.push suffex                 # the value to check against
            true
          end
        end
      end
    end
  end
end
