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
      if !user_signed_in?
        return head :unauthorized
      end

      if !(item = table.where(id: params[:id]).first)
        return head :not_found
      end

      if !item.owned_by(current_user)
        return head :unauthorized
      end

      yield(item)
      head :ok
    end

    def check_then(id)
      if !user_signed_in?
        return head :unauthorized
      end

      if !(album = Album.where(id: params[id]).first)
        return head :not_found
      end

      if !album.owned_by(current_user)
        return head :unauthorized
      end

      yield(album)
    end
  end
end
