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

			return records if !block_given? || !records.length

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
	end
end
