class Pagination
  def self.paginate(records, pageNumber, pageSize, reverse)
    if records.count == 0
      return Pagination.new(records, 0, 0, false)
    end
    if pageNumber.nil?
      pageNumber = 0
    end
    if records.count <= pageSize
      return Pagination.new(records, 0, 0, reverse)
    end
    if records.count <= pageNumber * pageSize || pageNumber < 0
      pageNumber = (records.count / pageSize)
    end
    if pageNumber < 0
      pageNumber = 0
    end
    return Pagination.new(records.offset(pageNumber * pageSize).limit(pageSize), records.count / pageSize, pageNumber, reverse)
  end
  
  def initialize(records, pages, page, reverse)
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
end