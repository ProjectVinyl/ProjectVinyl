module Albums
  module Orderable
    CREATED = 1
    ADDED = 2
    SCORE = 3

    def ordering_text
      return "date created" if ordering == CREATED
      return "score" if ordering == SCORE
      return "date added" if ordering == ADDED
      "custom"
    end

    def ordering_direction
      reverse_ordering ? "desc" : "asc"
    end

    def set_ordering(order, direction)
      self.ordering = order.to_i
      self.reverse_ordering = direction == '1'
      repaint_ordering(album_items)
    end

    def ordered(items)
      if ordering == SCORE
        items = items.joins(:video).order('videos.score')
        items = items.reverse_order if reverse_ordering
        return recalculate_ordering(items)
      end
      items.order('album_items.index')
    end

    def repaint_ordering(items)
      if ordering == CREATED
        items = items.joins(:video).order('videos.created_at')
      elsif ordering == ADDED
        items = items.order(:created_at)
      end

      items = items.reverse_order if reverse_ordering
      recalculate_ordering(items)
    end

    private
    def recalculate_ordering(items)
      items.each_with_index do |item, i|
        if item.index != i
          item.index = i
          item.save
        end
      end
      items
    end
  end
end
