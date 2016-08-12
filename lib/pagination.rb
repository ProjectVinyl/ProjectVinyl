class Pagination
  def self.paginate(records, pageNumber, pageSize, reverse)
    count = records.count
    if count == 0
      return Pagination.new(records, 0, 0, false, count)
    end
    if pageNumber.nil?
      pageNumber = 0
    end
    if count <= pageSize
      return Pagination.new(records, 0, 0, reverse, count)
    end
    pages = count / pageSize
    if (pages * pageSize) == count
      pages -= 1
    end
    if count <= pageNumber * pageSize || pageNumber < 0
      pageNumber = pages
    end
    if pageNumber < 0
      pageNumber = 0
    end
    return Pagination.new(records.offset(pageNumber * pageSize).limit(pageSize), pages, pageNumber, reverse, count)
  end
  
  def initialize(records, pages, page, reverse, count)
    @count = count
    @records = reverse ? records.reverse_order() : records
    @page = page
    @pages = pages
  end
  
  def records
    @records
  end
  
  def records=(inputter)
    @records = inputter
  end
  
  def page
    @page
  end
  
  def pages
    @pages
  end
  
  def count
    @count
  end
  
  def length
    @count
  end
end