module Admin
  module Tags
    class RulesController < BaseAdminController
      def index
        return render_access_denied if !current_user.is_contributor?

        @crumb = {
          stack: [
            { link: '/admin', title: 'Admin' }
          ],
          title: "Tag Rules"
        }
        @rules = TagRule.all
      end

      def update
        return render_status_page :unauthorized if !current_user.is_contributor?

        redirect_to action: :index

        if !(rule = TagRule.where(id: params[:tag_rule][:id]).first)
          return flash[:error] = "Error: Record not be found."
        end

        rule.update(read_in)
      end

      def new
        return head :unauthorized if !current_user.is_contributor?

        @rule = TagRule.new
        render partial: 'new'
      end

      def create
        redirect_to action: :index
        return flash[:error] = "Error: Login required." if !current_user.is_contributor?

        TagRule.create(read_in)
      end
      
      def read_in
        p = params[:tag_rule].permit(:when_present_tag_string,
          :all_of_tag_string,
          :none_of_tag_string,
          :any_of_tag_string,
          :message)

        {
          message: p[:message],
          when_present: Tag.split_to_ids(p[:when_present_tag_string]),
          all_of: Tag.split_to_ids(p[:all_of_tag_string]),
          none_of: Tag.split_to_ids(p[:none_of_tag_string]),
          any_of: Tag.split_to_ids(p[:any_of_tag_string])
        }
      end

      def destroy
        redirect_to action: :index
        return flash[:error] = "Error: Login required." if !current_user.is_contributor?

        if !(rule = TagRule.where(id: params[:id]).first)
          return render json: {
            error: "Error: Record not be found."
          }
        end

        rule.destroy
        
      end
    end
  end
end
