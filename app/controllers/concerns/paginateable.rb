module Paginateable
  def render_empty_pagination(partial)
    render json: {
      content: render_to_string(partial: 'pm/mailderpy'),
      pages: 0,
      page: 0
    }
  end
  
  def render_pagination(partial, records, page, page_size, reverse, locals = {})
    render_pagination_json(partial, Pagination.paginate(records, page, page_size, reverse), locals)
  end
  
  def pagination_json_for_render(partial, pagination, locals = {})
    {
      paginate: render_to_string(partial: 'pagination/numbering', locals: {
        results: pagination, pagination_id: '{page}'
      }),
      content: render_to_string(partial: partial, collection: pagination.records, locals: locals),
      pages: pagination.pages,
      page: pagination.page
    }
  end
  
  def render_pagination_json(partial, pagination, locals = {})
    render json: pagination_json_for_render(partial, pagination, locals)
  end
  
  def render_listing(records, page, page_size, reverse, locals)
    if locals[:id] < 0
      locals[:partial] = locals[:id] == -1 ? 'admin/video/thumb_h' : 'video/thumb_h'
    else
      locals[:partial] = locals[:label].underscore + '/thumb_h'
    end
    locals[:items] = Pagination.paginate(records, page, page_size, reverse)
    render template: 'pagination/listing', locals: locals
  end
end
