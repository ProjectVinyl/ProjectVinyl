module Admin
  module Tags
    class TypesController < BaseAdminController
      def index
        return render_access_denied if !current_user.is_contributor?

        @crumb = {
          stack: [
            { link: '/admin', title: 'Admin' }
          ],
          title: "Tag Types"
        }
        @types = TagType.includes(:tag_type_implications).all
      end

      def update
        if !current_user.is_contributor?
          return head :unauthorized if params[:format] == 'json'
          return render file: '/public/403.html', layout: false
        end

        redirect_to action: :index

        if !(tagtype = TagType.where(id: params[:tag_type][:id]).first)
          return flash[:error] = "Error: Record not be found."
        end

        prefix = Tag.sanitize_name(params[:tag_type][:prefix])

        return flash[:error] = "Error: Prefix cannot be blank/null" if !StringsHelper.valid_string?(prefix)

        if tagtype.prefix != prefix
          return flash[:error] = "Error: A tag type with that prefix already exists." if TagType.where(prefix: prefix).count > 0

          tagtype.prefix = prefix
        end

        tagtype.hidden = params[:tag_type][:hidden] == '1'
        tagtype.tag_string = params[:tag_type][:tag_string]
        tagtype.save
        tagtype.find_and_assign
      end

      def new
        return head :unauthorized if !current_user.is_contributor?

        @tagtype = TagType.new
        render partial: 'new'
      end

      def create
        redirect_to action: :index
        return flash[:error] = "Error: Login required." if !current_user.is_contributor?

        prefix = Tag.sanitize_name(params[:tag_type][:prefix])

        return flash[:error] = "Error: Prefix cannot be blank/null" if !StringsHelper.valid_string?(prefix)
        return flash[:error] = "Error: A tagtype with that prefix already exists" if TagType.where(prefix: prefix).count > 0

        tagtype = TagType.create(prefix: prefix, hidden: params[:tag_type][:hidden] == '1')
        tagtype.tag_string = params[:tag_type][:tag_string]
        tagtype.find_and_assign
      end

      def destroy
        redirect_to action: :index
        return flash[:error] = "Error: Login required." if !current_user.is_contributor?

        if !(tagtype = TagType.where(id: params[:id]).first)
          return render json: {
            error: "Error: Record not be found."
          }
        end

        tagtype.destroy
      end
    end
  end
end
