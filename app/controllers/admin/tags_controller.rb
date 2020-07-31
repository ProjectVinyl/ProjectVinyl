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

      if params[:tag][:alias_tag] && (@alias = Tag.by_name_or_id(params[:tag][:alias_tag]).first)
        @tag.set_alias(@alias)
      else
        @tag.unset_alias
      end

      @tag.tag_type = TagType.where(id: params[:tag][:tag_type_id]).first

      if !@tag.set_name(params[:tag][:suffex])
        flash[:alert] = "Duplicate Error: A Tag named '" + params[:tag][:suffex] + "' already exists"
        @tag.save
      end

      implications = Tag.split_to_ids(params[:tag][:tag_string])
      implications = TagImplication.expand(implications)
      implications |= @tag.tag_type.unique_implication_ids if @tag.tag_type

      TagImplication.load(@tag, implications)
    end
  end
end
