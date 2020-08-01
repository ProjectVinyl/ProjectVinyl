require 'projectvinyl/search/exceptable'

class Pagination
  include ProjectVinyl::Search::Exceptable
  attr_accessor :records
  attr_reader :page, :pages, :count, :page_size

  def self.paginate(records, page_number, page_size, reverse)
    records = records.reverse_order if reverse
    count = records.size

    return Pagination.new(records, page_size, 0, 0, count) if count == 0

    page_number = 0 if page_number.nil?

    return Pagination.new(records, page_size, 0, 0, count) if count <= page_size

    pages = count / page_size
    pages -= 1 if (pages * page_size) == count

    page_number = pages if count <= page_number * page_size || page_number < 0
    page_number = 0 if page_number < 0

    Pagination.new(records.offset(page_number * page_size).limit(page_size), page_size, pages, page_number, count)
  end

  def initialize(records, limit, pages, page, count)
    @page_size = limit
    @offset = page * limit
    @count = count
    @records = records
    @page = page
    @pages = pages
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
