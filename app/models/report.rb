# TODO: Reports are a mess
class Report < ApplicationRecord
  include Indirected
  
  belongs_to :reportable, polymorphic: true

  has_one :comment_thread, as: :owner, dependent: :destroy
	
  scope :open, -> { where(resolved: nil) }
  scope :closed, -> { where(resolved: false) }
  scope :solved, -> { where(resolved: true) }
  
  STATE_TO_STATUS = {
    open: [:reopened, nil],
    close: [:closed, false],
    resolve: [:resolved, true]
  }
  
  def self.generate_report(params)
    report = Report.create(params)
    report.comment_thread = CommentThread.create(
      user_id: params[:user_id],
      title: "Report: " + params[:reportable].reportable_name
    )
    report.save
    Notification.notify_admins(report,
      "A new <b>Report</b> has been submitted for <b>#{params[:reportable].reportable_name}</b>",
      report.comment_thread.location
    )
  end
  
	def note
		other
	end
	
	def target
		source
	end
	
  def write(msg)
    self.other << "<br>#{msg}"
  end
  
  def status
    self.resolved.nil? ? "Open" : self.resolved ? "Resolved" : "Closed"
  end
  
  def source_label
    first == "duplicate" ? "Target Video" : "Source"
  end
  
  def open?
    self.resolved.nil?
  end
  
  def bump(sender, params, comment)
    state = params[:report_state]
    
    if state.nil?
      return
    end
    
    status = STATE_TO_STATUS[state.to_sym]
    
    if self.resolved != status[1]
      self.resolved = status[1]
      Notification.notify_admins(self, "Report <b>#{sender.title}</b> has been #{status[0]}", sender.location)
      self.save
    end
  end
end
