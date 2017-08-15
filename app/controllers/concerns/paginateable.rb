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
        page: pagination.page, pages: pagination.pages, id: '{page}'
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
    locals[:partial] = partial_for_type(locals[:label], locals[:is_admin])
    render_listing_partial(records, page, page_size, reverse, locals)
  end
  
  def render_listing_partial(records, page, page_size, reverse, locals)
    locals[:items] = Pagination.paginate(records, page, page_size, reverse)
    render template: 'pagination/listing', locals: locals
  end
  
  def partial_for_type(type, is_admin)
    "#{is_admin ? 'admin/' : '' }#{type.to_s.underscore}/thumb_h"
  end
end
