module Admin
  module Forum
    class BadgesController < BaseAdminController
      def index
        return render_access_denied if !current_user.is_contributor?

        @crumb = {
          stack: [
            { link: '/admin', title: 'Admin' }
          ],
          title: "Badges"
        }
        @badges = Badge.all
      end
      
      def new
        return render_access_denied if !current_user.is_contributor?

        @badge = Badge.new
        render partial: 'new'
      end
      
      def create
        check_first do
          @badge = Badge.create(params[:badge].permit(:title, :colour, :icon, :badge_type, :note, :description, :hidden))
        end
      end
      
      def update
        check_then do
          @badge.update_attributes(params[:badge].permit(:title, :colour, :icon, :badge_type, :note, :description, :hidden))
        end
      end
      
      def destroy
        check_then do
          @badge.destroy
          flash[:notice] = "Record deleted.";
        end
      end
      
      private
      def check_first
        redirect_to action: :index
        
        return flash[:error] = "Error: Login required." if !current_user.is_contributor?
        yield
      end
      
      def check_then
        check_first do
          return flash[:error] = "Error: Record not found." if !(@badge = Badge.where(id: params[:id]).first)
          yield
        end
      end
    end
  end
end
