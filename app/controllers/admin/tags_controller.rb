module Admin
  class TagsController < BaseAdminController
    def show
      return render_access_denied if !current_user.is_contributor?

      @tag = Tag.find(params[:id])
      @prefix = @tag.tag_type_id && @tag.tag_type_id > 0 ? @tag.tag_type.prefix : "[none]"
      @user = User.where(tag_id: @tag.id).first
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { title: 'Tags' },
          { link: @tag.link, title: @tag.id }
        ],
        title: @tag.name
      }
    end

    def update
      return render_access_denied if !current_user.is_staff?

      redirect_to action: :show

      if !(@tag = Tag.where(id: params[:id]).first)
        return flash[:error] = "Error: Record not found."
      end

      @tag.description = params[:tag][:description]

      if params[:tag][:alias_tag] && (@alias = Tag.by_name_or_id(params[:tag][:alias_tag]).first.actual)
        alias_tag
      elsif @tag.alias
        unalias_tag
      end

      @tag.tag_type = TagType.where(id: params[:tag][:tag_type_id]).first
      @tag.name = params[:tag][:suffex]

      return flash[:alert] = "Duplicate Error: A Tag named '" + params[:tag][:suffex] + "' already exists" if @tag.invalid?

      @tag.save

      implications = Tag.split_to_ids(params[:tag][:tag_string])
      implications = TagImplication.expand(implications)
      implications |= @tag.tag_type.unique_implication_ids if @tag.tag_type

      TagImplication.load(@tag, implications)
    end

    private
    def alias_tag
      return if @alias.id == @tag.id || @alias.id == @tag.alias_id

      @tag.alias = @alias

      # Move existing aliases for this tag to the target tag
      Tag.where(alias_id: @tag.id).update_all(alias_id: @alias.id)
      # Replace instances of this tag with the target tag
      User.where(tag_id: @tag.id).update_all(tag_id: @alias.id)
      ArtistGenre.where(o_tag_id: @tag.id).update_all(tag_id: @alias.id)
      VideoGenre.where(o_tag_id: @tag.id).update_all(tag_id: @alias.id)

      @tag.video_count = @tag.user_count = 0
      @alias.reindex!
      @tag.reindex!
    end

    def unalias_tag
      return if !(@alias = @tag.alias)

      @tag.alias = nil

      # Reset usages of this tag back to what they were originally.
      ArtistGenre.where(o_tag_id: @tag.id).update_all('tag_id = o_tag_id')
      VideoGenre.where(o_tag_id: @tag.id).update_all('tag_id = o_tag_id')

      @alias.reindex!
      @tag.reindex!
    end
  end
end
