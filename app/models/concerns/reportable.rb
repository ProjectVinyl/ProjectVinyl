module Reportable
  extend ActiveSupport::Concern
	
  def self.find(params)
    type = params[:reportable_class].constantize
    type.where(id: params[:reportable_id]).first
  end
  
  included do
    has_many :reports, as: :reportable
    
    def open_reports
      reports.open
    end
    
    def closed_reports
      reports.closed
    end
    
    def resolved_reports
      reports.solved
    end
  end
  
  def report(sender_id, params)
		
  end
  
  def reportable_name
    "#{self.class.table_name}_#{self.id}"
  end
  
  def reportable_params
    "reportable_class=#{self.class}&reportable_id=#{self.id}"
  end
end
