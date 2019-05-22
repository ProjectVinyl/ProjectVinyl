module Admin
  class TagsController < BaseAdminController
    def show
      if !current_user.is_contributor?
        return render_access_denied
      end
      
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
      if !current_user.is_staff?
        return render_access_denied
      end
      
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
      
      implications = Tag.split_tag_string(params[:tag][:tag_string])
      implications = Tag.get_tag_ids(implications)
      implications = Tag.expand_implications(implications)
      
      if @tag.tag_type
        implications |= @tag.tag_type.tag_type_implications.pluck(:implied_id).uniq
      end
      
      TagImplication.where(tag_id: @tag.id).destroy_all
      
      implications = implications.uniq.map do |i|
        { tag_id: @tag.id, implied_id: i }
      end
      
      TagImplication.create(implications)
    end
  end
end
