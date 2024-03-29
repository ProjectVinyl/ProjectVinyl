class TagsController < ApplicationController
  include Searchable

  configure_ordering [ :name, :video_count, :user_count ], only: [:index]
  configure_ordering [ :date, :rating, [:wilson_score, :wilson_lower_bound], :heat, :length, :random, :relevance ], search_action: :search_index_path, only: [:show]

  def show
    name = params[:id].downcase
    if !(@tag = Tag.by_name_or_id(name).first)
      return render_error(
        title: 'Nothing to see here but us Fish!',
        description: 'This tag does not exist.'
      )
    end

    if @tag.alias_id
      flash[:notice] = "The tag '#{@tag.name}' has been aliased to '#{@tag.alias.name}'"
      if !user_signed_in? || !current_user.is_staff?
        return redirect_to action: :show, id: @tag.alias.short_name
      end
    end

    params[query_term] = @tag.name
    read_search_params params

    @modifications_allowed = user_signed_in? && current_user.is_contributor?

    @total_videos = @tag.videos.count
    @total_users = @tag.users.count

    @videos = current_filter.videos
        .must({ term: {tags: @tag.name } })
        .where(hidden: false)
        .order(:created_at)
        .reverse_order
        .paginate(0, 8) {|recs| recs.for_thumbnails(current_user) }

    @users = Pagination.paginate(@tag.users.order(:updated_at), 0, 8, true)

    @user = User.where(tag_id: @tag.id).first if @tag.namespace == 'artist'

    @implies = @tag.implications.ordered
    @implied = @tag.implicators.ordered
    @aliases = @tag.aliases.ordered

    @crumb = {
      stack: [
        { link: tags_path, title: 'Tags' }
      ],
      title: @tag.name
    }
  end

  def index
    read_search_params params, default_order: 1, default_order_by: 1

    if filtered?
      @records = ProjectVinyl::Search::ActiveRecord.new(Tag)
        .must(ProjectVinyl::Search.interpret(@query, ProjectVinyl::Search::TAG_INDEX_PARAMS, current_user).to_hash)
        .order(order_field)
      @records = @records.reverse_order if !@ascending
      @records = @records.paginate(@page, 100){|recs| recs.includes(:videos, :tag_type)}
    else
      @records = Pagination.paginate(Tag.includes(:videos, :tag_type).where(alias_id: nil).order(order_field), @page, 100, !@ascending)
    end

    render_paginated @records, {
      template: 'pagination/omni_search', table: 'tags', label: 'Tag'
    }
  end
end
