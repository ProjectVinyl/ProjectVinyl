class Pagination
  def self.paginate(records, pageNumber, pageSize, reverse)
    count = records.count
    return Pagination.new(records, pageSize, 0, 0, false, count) if count == 0
    pageNumber = 0 if pageNumber.nil?
    if count <= pageSize
      return Pagination.new(records, pageSize, 0, 0, reverse, count)
    end
    pages = count / pageSize
    pages -= 1 if (pages * pageSize) == count
    pageNumber = pages if count <= pageNumber * pageSize || pageNumber < 0
    pageNumber = 0 if pageNumber < 0
    Pagination.new(records.offset(pageNumber * pageSize).limit(pageSize), pageSize, pages, pageNumber, reverse, count)
  end

  def initialize(records, limit, pages, page, reverse, count)
    @size = limit
    @count = count
    @records = reverse ? records.reverse_order : records
    @page = page
    @pages = pages
  end

  attr_reader :records

  attr_writer :records

  attr_reader :page

  def page_size
    @size
  end

  attr_reader :pages

  attr_reader :count

  def length
    @count
  end
end
