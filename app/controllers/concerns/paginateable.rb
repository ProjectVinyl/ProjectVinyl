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
    locals[:partial] = partial_for_type(locals[:table], locals[:is_admin]) if !locals.key?(:partial)
    locals[:type] = "#{locals[:scope] ? locals[:scope].to_s + "/" : ""}#{locals[:table]}"

    @crumb = {
      stack: [],
      title: locals[:label].pluralize
    }

    return render_pagination locals[:partial], records, page, page_size, reverse if params[:format] == 'json'

    render_listing_partial records, page, page_size, reverse, locals
  end

  def render_paginated(pagination, locals = {})
    locals[:partial] = partial_for_type(locals[:table], locals[:is_admin]) if !locals.key?(:partial)
    locals[:type] = "#{locals[:scope] ? locals[:scope].to_s + "/" : ""}#{locals[:table]}"
    locals[:items] = pagination

    @crumb = {
      stack: [],
      title: locals[:label].pluralize
    }

    template = locals[:template] ? locals[:template] : 'pagination/listing'
    render template: template, locals: locals
  end

  def render_listing(records, page, page_size, reverse, locals)
    locals[:partial] = partial_for_type(locals[:label], locals[:is_admin])
    render_listing_partial(records, page, page_size, reverse, locals)
  end

  def render_listing_partial(records, page, page_size, reverse, locals)
    locals[:items] = Pagination.paginate(records, page, page_size, reverse)
    template = locals[:template] ? locals[:template] : 'pagination/listing'
    render template: template, locals: locals
  end

  def partial_for_type(type, is_admin = false)
    "#{type.to_s.underscore}/thumb/#{is_admin ? 'admin' : 'normal' }"
  end
end
