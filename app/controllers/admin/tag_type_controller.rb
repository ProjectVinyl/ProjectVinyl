module Admin
  class TagTypeController < ApplicationController
    before_action :authenticate_user!
    
    def index
      if !current_user.is_contributor?
        return render_access_denied
      end
      @types = TagType.includes(:tag_type_implications).all
    end
    
    def update
      if !current_user.is_contributor?
        if params[:format] == 'json'
          return head 403
        end
        return render file: '/public/403.html', layout: false
      end
      
      redirect_to action: 'index'
      
      if !(tagtype = TagType.where(id: params[:tag_type][:id]).first)
        flash[:error] = "Error: Record not be found."
      end
      
      if error = tagtype.set_metadata(params[:tag_type][:prefix], params[:tag_type][:hidden] == '1')
        flash[:error] = error
      end
      Tag.load_tags(params[:tag_type][:tag_string], tagtype)
    end

    def new
      if !current_user.is_contributor?
        return head 403
      end

      @tagtype = TagType.new
      render partial: 'new'
    end

    def create
      redirect_to 'index'
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      prefix = Tag.sanitize_name(params[:tag_type][:prefix])
      
      if !ApplicationHelper.valid_string?(prefix)
        return flash[:error] = "Error: Prefix cannot be blank/null"
      end
      
      if TagType.where(prefix: prefix).count > 0
        return flash[:error] = "Error: A tagtype with that prefix already exists"
      end
      
      tagtype = TagType.create(prefix: prefix, hidden: params[:tag_type][:hidden] == '1')
      Tag.load_tags(params[:tag_type][:tag_string], tagtype)
      tagtype.find_and_assign
    end

    def delete
      if !current_user.is_contributor?
        return head 403
      end
      
      if !(tagtype = TagType.where(id: params[:id]).first)
        return render json: {
          error: "Error: Record not be found."
        }
      end
      
      Tag.where(tag_type_id: tagtype.id).update_all('tag_type_id = 0')
      tagtype.destroy
      render json: {
      }
    end
  end
end
