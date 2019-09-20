class InboxController < Inbox::BaseInboxController
  def show
    @type = params[:type] || 'new'
    @result = paginate_for_type(@type)
    @counts = tab_changes

    if params[:format] == 'json'
      if params[:tabs]
        return render json: {
          content: render_to_string(partial: 'inbox/list_group', locals: {
            type: @type,
            paginated: @result,
            selected: true
          }, formats: [:html]),
          tabs: @counts
        }
      end

      if @result.count == 0
        return render_empty_pagination 'inbox/pm/mailderpy'
      end

      @json = pagination_json_for_render 'inbox/pm/thumb', @result
      @json[:tabs] = @counts

      return render json: @json
    end
  end
end
