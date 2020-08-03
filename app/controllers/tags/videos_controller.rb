module Tags
  class VideosController < ApplicationController
    def index
      return head :not_found if !(@tag = Tag.where(id: params[:tag_id]).first)
      @records = current_filter.videos
        .must({ term: {tags: @tag.name } })
        .where(hidden: false)
        .order(:created_at)
        .reverse_order
        .paginate(params[:page].to_i, 8) {|recs| recs.for_thumbnails(current_user) }

      render_pagination_json partial_for_type(:videos), @records
    end
  end
end
