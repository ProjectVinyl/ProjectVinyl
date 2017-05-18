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
        return render status: 403, nothing: true
      end
      return render file: '/public/403.html', layout: false
    end
    
    if tagtype = TagType.where(id: params[:tag_type][:id]).first
      if error = tagtype.set_prefix(params[:tag_type][:prefix])
        flash[:error] = error
      end
      Tag.loadTags(params[:tag_type][:tag_string], tagtype)
    else
      flash[:error] = "Error: Record not be found."
    end
    
    redirect_to action: 'view'
  end
  
  def new
    if !user_signed_in? || !current_user.is_contributor?
      return render status: 403, nothing: true
    end
    @tagtype = TagType.new
    render partial: 'new'
  end
  
  def create
    if !user_signed_in? || !current_user.is_contributor?
      return render status: 403, nothing: true
    end
  end
  
  def delete
    if !user_signed_in? || !current_user.is_contributor?
      return render status: 403, nothing: true
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
