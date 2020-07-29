module Albums
  class BaseAlbumsController < ApplicationController
    protected
    def check_and
      if !user_signed_in?
        flash[:error] = "You need to sign in to do that."
        return redirect_to action: :index, controller: :welcome
      end

      yield
    end

    def check_then_with(table)
      return head :unauthorized if !user_signed_in?
      return head :not_found if !(item = table.where(id: params[:id]).first)
      return head :unauthorized if !item.owned_by(current_user)
      yield(item)
      head :ok
    end

    def check_then(id)
      return head :unauthorized if !user_signed_in?
      return head :not_found if !(album = Album.where(id: params[id]).first)
      return head :unauthorized if !album.owned_by(current_user)
      yield(album)
    end
  end
end
