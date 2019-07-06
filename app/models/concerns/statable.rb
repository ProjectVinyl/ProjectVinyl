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
			records = select("COUNT(*) AS total, date(#{table_name}.created_at) as created_on").group("created_on").order("created_on").reverse_order
			
			if !origin.nil?
				last = Time.zone.now.beginning_of_day + 1.day
				records = records.where("created_at > ?", last - origin.days)
			else
				last = records.first.created_at.beginning_of_day + 1.day
			end
			
			return records if !block_given?
			return records if !records.length
			
			max = select("COUNT(*) AS total, date(#{table_name}.created_at) AS created_on").group("created_on").order('total').reverse_order.limit(1).first
			max = max.nil? ? 9 : max.total.to_f
			
			index = -1
			records.each do |current|
				day = current.created_on
				while day <= last - 1.day
					last = last - 1.day
					index = index + 1
					yield({
						total: last == day ? (current.total / max) * 100 : 0,
						count: last == day ? current.total : 0,
						created_at: last
					}, index)
				end
			end
			
			return if origin.nil?
			
			while index < origin
				last = last - 1.day
				index = index + 1
				yield({
					total: 0, count: 0, created_at: last
				}, index)
			end
		end
	end
end
