class InboxController < ApplicationController
  def show
    @type = params[:type] || 'new'
    @result = paginate_for_type(@type)
    @counts = tab_changes
  end
  
  def page
    @type = params[:type]
    @results = paginate_for_type(@type)
    if @results.count == 0
      return render_empty_pagination 'pm/mailderpy'
    end
    @json = pagination_json_for_render 'pm/thumb', @results
    @json[:tabs] = tab_changes
    render json: @json
  end
  
  def tab
    @type = params[:type]
    render json: {
      content: render_to_string(partial: 'inbox/list_group', locals: {
        type: @type,
        paginated: paginate_for_type(@type),
        selected: true
      }),
      tabs: tab_changes
    }
  end
  
  protected
  def tab_changes(type = nil, results = nil)
    {
      new: count_for_type('new')
    }
  end
  
  def count_for_type(type)
    Pm.find_for_tab_counter(type, current_user).count
  end
  
  def page_for_type(type)
    Pm.find_for_tab(type, current_user)
  end
  
  def paginate_for_type(type)
    Pagination.paginate(page_for_type(type), params[:page].to_i, 50, false)
  end
end