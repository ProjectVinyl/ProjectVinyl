module Paginateable
  def render_empty_pagination(partial)
    render json: {
      content: render_to_string(partial: partial, formats: :html),
      pages: 0,
      page: 0
    }
  end

  def render_pagination(records, page, page_size, reverse, locals)
    render_paginated(Pagination.paginate(records, page, page_size, reverse), locals)
  end

  def render_paginated(pagination, locals = {})
    locals[:partial] = partial_for_type(locals[:table], locals[:is_admin]) if !locals.key?(:partial)
    locals[:type] = "#{locals[:scope] ? locals[:scope].to_s + "/" : ""}#{locals[:table]}"
    locals[:items] = pagination

    return render json: pagination_json_for_render(pagination, locals) if locals[:as] == :json || params[:format] == 'json'

    @crumb = { stack: [], title: locals[:label].pluralize }

    template = locals[:template] ? locals[:template] : 'pagination/listing'
    render template: template, locals: locals
  end

  def pagination_json_for_render(pagination, locals = {})
    c = render_to_string(partial: locals[:partial], collection: pagination.records, formats: [:html], locals: locals)
    c = render_to_string(partial: locals[:headers], formats: [:html]) + c  if locals.key?(:headers)

    {
      paginate: render_to_string(partial: 'pagination/numbering', formats: [:html], locals: {
        page: pagination.page,
        pages: pagination.pages,
        id: '{page}',
        order: pagination.reverse ? 1 : 0
      }),
      content: c,
      pages: pagination.pages,
      page: pagination.page
    }
  end

  def partial_for_type(type, is_admin = false)
    "#{type.to_s.underscore}/thumb/#{is_admin ? 'admin' : 'normal' }"
  end
end
