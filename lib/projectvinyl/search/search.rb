require 'projectvinyl/search/parser/parsed_query'
require 'projectvinyl/search/parser/opset'
require 'projectvinyl/search/parser/op'
require 'projectvinyl/search/parser/index'
require 'projectvinyl/search/order'

module ProjectVinyl
  module Search
    VIDEO_INDEX_PARAMS = ProjectVinyl::Search::Parser::Index.new(Video, {
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
      has: {
        album: :albums
      },
      fields: {
        title: :title,
        source: :source,
        description: :description,
        mime_type: :mime
      },
      range_fields: {
        aspect_ratio: :aspect,
        length: :length,
        width: :width,
        height: :height,
        score: :score,
        wilson_score: :wilson_lower_bound,
        file_size: :size,
        heat: :heat,
        uploaded: :created_at
      }
    })
    USER_INDEX_PARAMS = ProjectVinyl::Search::Parser::Index.new(User, {
      fields: {
        username: :username
      },
      range_fields: {
        created: :created_at
      },
      hash: :tags
    }) do |sender, opset, slurp|
      opset.push :username
      opset.push slurp
      Parser::Op::TEXT_EQUAL
    end

    TAG_INDEX_PARAMS = ProjectVinyl::Search::Parser::Index.new(Tag, {
      fields: {
        name: :name,
        slug: :slug,
        namespace: :namespace
      },
      has: {
        :alias => :aliases,
        implies: :implications,
        implied_by: :implicators
      },
      range_fields: {
        videos: :video_count,
        users: :user_count
      }
    }) do |sender, opset, slurp|
      opset.push :name
      opset.push slurp
      Parser::Op::TEXT_EQUAL
    end
    
    def self.ordering(type, session, order_by, ascending)
      Order.parse(type, session, order_by, ascending)
    end

    def self.interpret(search_terms, index_params, sender = nil)
      Parser::ParsedQuery.new(search_terms, index_params, sender)
    end
  end
end
