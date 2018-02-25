module Reportable
  extend ActiveSupport::Concern
	
  REPORTABLE_TYPES = {}
  
  def self.types
    REPORTABLE_TYPES
  end
  
  def self.find(params)
    type = REPORTABLE_TYPES[params[:reportable_class].to_sym]
    type.where(id: params[:reportable_id]).first
  end
  
  included do
    REPORTABLE_TYPES[self.to_s.downcase.to_sym] = self
    
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
end
