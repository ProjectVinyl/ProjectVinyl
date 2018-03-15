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
  
  def self.prepare_params(params)
    params[:resolved] = nil
    params
  end
  
  def self.generate_report(params)
    Report.generate_report!(
      "Report: " + params[:reportable].reportable_name,
      "A new <b>Report</b> has been submitted for <b>#{params[:reportable].reportable_name}</b>",
      params
    )
  end
  
  def self.generate_report!(title, message, params)
    Report.create_report!(title, params).notify_admins(message)
  end
  
  def self.report_on(title, message, params)
    report = Report.create_report!(title, params)
    yield(report)
    report.notify_admins(message)
  end
  
  def self.create_report!(title, params)
    report = Report.create!(Report.prepare_params(params))
    report.comment_thread = CommentThread.create!(
      user_id: params[:user_id],
      title: title
    )
    report
  end
  
  def notify_admins(message)
    self.save!
    Notification.notify_admins(self, message, self.comment_thread.location)
  end
  
	def note
		other
	end
	
	def target
		source
	end
  
  def link
    "/admin/reports/#{self.id}"
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
      self.notify_admins("Report <b>#{sender.title}</b> has been #{status[0]}")
    end
  end
end
