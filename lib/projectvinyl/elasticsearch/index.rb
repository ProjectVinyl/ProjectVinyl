require 'projectvinyl/elasticsearch/op'

module ProjectVinyl
  module ElasticSearch
    class Index
      def initialize(params = {})
        @params = params
      end
      VIDEO_INDEX_PARAMS = Index.new({
        my: {
          upvotes: :likes,
          downvotes: :dislikes,
          uploads: :user_id
        },
        by: {
          uploaded_by: :user_id,
          upvoted_by: :likes,
          downvoted_by: :dislikes
        },
        is: {
          audio: :audio_only,
          hidden: :hidden
        },
        fields: {
          title: :title,
          source: :source,
          description: :description
        },
        range_fields: {
          aspect_ratio: :aspect,
          length: :length,
          width: :width,
          height: :height,
          score: :score,
          file_size: :size,
          heat: :heat,
          uploaded: :created_at
        }
      })
      USER_INDEX_PARAMS = Index.new({
        my: {},
        by: {},
        is: {},
        fields: {
          name: :username
        },
        range_fields: {
          created: :created_at
        }
      })

      CHAR_OP_LOOKUP = {
        ':': ProjectVinyl::ElasticSearch::Op::EQUAL,
        '>': ProjectVinyl::ElasticSearch::Op::GREATER_THAN,
        '<': ProjectVinyl::ElasticSearch::Op::LESS_THAN
      }.freeze

      def slurp_tags(opset, slurp)
        slurp = slurp.strip
        slugs = slurp.split(/[<>:]/)

        return slurp if slugs.length <= 0

        prefix = slugs[0]
        separator = slurp[prefix.length...(prefix.length + 1)].to_sym
        suffex = slurp[(prefix.length + 1)...slurp.length].strip.downcase

        prefix = prefix.to_sym

        # Self-based tags
        return Op::MY if check_pre(opset, :my, prefix, suffex, nil)
        # Boolean set operators
        return Op::EQUAL if check_pre(opset, :is, prefix, suffex, true)
        # User-based tags
        return Op::MY if check_post(opset, :by, prefix, suffex)
        # Greater than, less than, or equals
        return CHAR_OP_LOOKUP[separator] if check_post(opset, :range_fields, prefix, suffex)
        # Only equals
        return Op::TEXT_EQUAL if check_post(opset, :fields, prefix, suffex)

        slurp
      end

      def check_pre(opset, group, prefix, suffex, value)
        suffex = suffex.to_sym
        if prefix == group && @params[group].key?(suffex)
          opset.push @params[group][suffex] # the field to check
          opset.push value                  # the value
          true
        end
      end

      def check_post(opset, group, prefix, suffex)
        if @params[group].key?(prefix)
          opset.push @params[group][prefix] # the field to check
          opset.push suffex                 # the value to check against
          true
        end
      end
    end
  end
end
