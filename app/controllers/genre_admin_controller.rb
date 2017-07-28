class GenreAdminController < ApplicationController
  def view
    if !user_signed_in? || !current_user.is_contributor?
      return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
    end
    @types = TagType.includes(:tag_type_implications).all
  end

  def update
    if !user_signed_in? || !current_user.is_contributor?
      if params[:ajax]
        return head 403
      end
      return render file: '/public/403.html', layout: false
    end

    if tagtype = TagType.where(id: params[:tag_type][:id]).first
      if error = tagtype.set_metadata(params[:tag_type][:prefix], params[:tag_type][:hidden] == '1')
        flash[:error] = error
      end
      Tag.load_tags(params[:tag_type][:tag_string], tagtype)
    else
      flash[:error] = "Error: Record not be found."
    end

    redirect_to action: 'view'
  end

  def new
    if !user_signed_in? || !current_user.is_contributor?
      return head 403
    end

    @tagtype = TagType.new
    render partial: 'new'
  end

  def create
    if !user_signed_in? || !current_user.is_contributor?
      return head 403
    end
    prefix = Tag.sanitize_name(params[:tag_type][:prefix])
    if !ApplicationHelper.valid_string?(prefix)
      flash[:error] = "Error: Prefix cannot be blank/null"
    else
      if TagType.where(prefix: prefix).count > 0
        flash[:error] = "Error: A tagtype with that prefix already exists"
      else
        tagtype = TagType.create(prefix: prefix, hidden: params[:tag_type][:hidden] == '1')
        Tag.load_tags(params[:tag_type][:tag_string], tagtype)
        tagtype.find_and_assign
      end
    end
    redirect_to 'view'
  end

  def delete
    if !user_signed_in? || !current_user.is_contributor?
      return head 403
    end
    if tagtype = TagType.where(id: params[:id]).first
      Tag.where(tag_type_id: tagtype.id).update_all('tag_type_id = 0')
      tagtype.destroy
    else
      return render json: {
        error: "Error: Record not be found."
      }
    end
    render json: {}
  end
end
