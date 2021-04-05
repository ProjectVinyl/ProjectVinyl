#
# Usage:
#    Model.stats do |item, index|
#      . . .
#    end
#
module Statable
	extend ActiveSupport::Concern

	included do
		def self.stats(origin = nil)
			records = select("COUNT(*) AS total, date(#{table_name}.created_at) as created_on")
        .group("created_on")
        .order("created_on")
        .reverse_order

      last = Time.zone.now.end_of_day

      records = records.where("created_at >= ?", last - origin.days) if !origin.nil?

			return records if !records.length

			max = select("COUNT(*) AS total, date(#{table_name}.created_at) AS created_on")
        .group("created_on")
        .order('total')
        .reverse_order
        .limit(1)
      max = max.where("created_at >= ?", last - origin.days) if !origin.nil?
      max = max.first

      return records if max.nil?

      max = max.total.to_f

      last = last.to_date.mjd
      len = origin.nil? ? 1 : (1 / origin.to_f)

      if !block_given?
        return records.map do |current|
          {
            spacing: len,
            x: last  - current.created_on.mjd,
            y: current.total / max,
            value: current.total,
            created_at: current.created_on
          }
        end
      end

			records.each do |current|
        yield({
          spacing: len,
          x: last  - current.created_on.mjd,
          y: current.total / max,
          value: current.total,
          created_at: current.created_on
        })
			end
		end
    
    def self.line_graph(origin = nil)
      commands = ''
      commands_accum = ''
      ending_x = 0
      accum_y = 0
      items = stats
      items.each do |item|
        ending_x = item[:x]
        ending_y = 100 - (item[:y] * 90)
        accum_y += item[:y]
        commands += " L #{ending_x},#{ending_y}"
        commands_accum += " L #{ending_x},#{accum_y * 50}"
      end
      
      items = items.map do |item|
        {
          value: item,
          node: {
            cx: item[:x],
            cy: 100 - (item[:y] * 90),
            rx: 5,
            ry: 5
          }
        }
      end
      
      {
        values: items,
        final_value: ending_x,
        sequence: {
          d: "M 0,100 #{commands} L #{ending_x * 2},100"
        },
        accumulation: {
          d: "M 0,100 L 0,#{accum_y * 50} #{commands_accum} L #{ending_x * 2},100"
        }
      }
    end
	end
end
