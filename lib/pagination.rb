class Pagination
  attr_accessor :records
  attr_reader :page, :pages, :count, :page_size
  
  def self.paginate(records, page_number, page_size, reverse)
    count = records.size
    if count == 0
      return Pagination.new(records, page_size, 0, 0, false, count)
    end
    if page_number.nil?
      page_number = 0
    end
    if count <= page_size
      return Pagination.new(records, page_size, 0, 0, reverse, count)
    end
    pages = count / page_size
    if (pages * page_size) == count
      pages -= 1
    end
    if count <= page_number * page_size || page_number < 0
      page_number = pages
    end
    if page_number < 0
      page_number = 0
    end

    Pagination.new(records.offset(page_number * page_size).limit(page_size), page_size, pages, page_number, reverse, count)
  end
  
  def initialize(records, limit, pages, page, reverse, count)
    @page_size = limit
    @offset = page * limit
    @count = count
    @records = reverse ? records.reverse_order : records
    @page = page
    @pages = pages
  end
  
  def error
    false
  end

  def length
    @count
  end
  
  def page_offset_start
    @offset
  end
  
  def page_offset_end
    [length, page_offset_start + @page_size].min
  end
end
