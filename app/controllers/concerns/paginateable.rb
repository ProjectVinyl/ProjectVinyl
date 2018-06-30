module Paginateable
  def render_empty_pagination(partial)
    render json: {
      content: render_to_string(partial: partial, formats: :html),
      pages: 0,
      page: 0
    }
  end
  
  def render_pagination(partial, records, page, page_size, reverse, locals = {})
    render_pagination_json(partial, Pagination.paginate(records, page, page_size, reverse), locals)
  end
  
  def pagination_json_for_render(partial, pagination, locals = {})
    {
      paginate: render_to_string(partial: 'pagination/numbering', formats: [:html], locals: {
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
  
  def render_listing_total(records, page, page_size, reverse, locals)
    locals[:partial] = partial_for_type(locals[:table], locals[:is_admin])
    locals[:type] = "#{locals[:scope] ? locals[:scope].to_s + "/" : ""}#{locals[:table]}"
    
    @crumb = {
      stack: [],
      title: locals[:label].pluralize
    }
    
    if params[:format] == 'json'
      return render_pagination locals[:partial], records, page, page_size, reverse
    end
    
    render_listing_partial records, page, page_size, reverse, locals
  end
  
  def render_listing(records, page, page_size, reverse, locals)
    locals[:partial] = partial_for_type(locals[:label], locals[:is_admin])
    render_listing_partial(records, page, page_size, reverse, locals)
  end
  
  def render_listing_partial(records, page, page_size, reverse, locals)
    locals[:items] = Pagination.paginate(records, page, page_size, reverse)
    render template: 'pagination/listing', locals: locals
  end
  
  def partial_for_type(type, is_admin = false)
    "#{is_admin ? 'admin/' : '' }#{type.to_s.underscore}/thumb_h"
  end
end
