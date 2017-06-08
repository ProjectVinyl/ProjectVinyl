class Pagination
  attr_accessor :records
  attr_reader :page, :pages, :count

  def self.paginate(records, page_number, page_size, reverse)
    count = records.count
    return Pagination.new(records, page_size, 0, 0, false, count) if count == 0
    page_number = 0 if page_number.nil?
    if count <= page_size
      return Pagination.new(records, page_size, 0, 0, reverse, count)
    end
    pages = count / page_size
    pages -= 1 if (pages * page_size) == count
    page_number = pages if count <= page_number * page_size || page_number < 0
    page_number = 0 if page_number < 0
    Pagination.new(records.offset(page_number * page_size).limit(page_size), page_size, pages, page_number, reverse, count)
  end

  def initialize(records, limit, pages, page, reverse, count)
    @size = limit
    @count = count
    @records = reverse ? records.reverse_order : records
    @page = page
    @pages = pages
  end

  def page_size
    @size
  end

  def length
    @count
  end
end
