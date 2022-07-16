# TODO: Reports are a mess
class Report < ApplicationRecord
	include Indirected

	belongs_to :reportable, polymorphic: true

	has_one :comment_thread, as: :owner, dependent: :destroy

	scope :open, -> { where(resolved: nil) }
	scope :closed, -> { where(resolved: false) }
	scope :solved, -> { where(resolved: true) }

	scope :change_status, ->(status) { update_all(resolved: STATE_TO_STATUS[status][1]) }

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
		Report.create_report!(title, params).send_update_notification(message)
	end

	def self.report_on(title, message, params)
		report = Report.create_report!(title, params)
		yield(report)
		report.send_update_notification(message)
	end

	def self.create_report!(title, params)
		report = Report.create!(Report.prepare_params(params))
		report.comment_thread = CommentThread.create!(
			user_id: params[:user_id],
			title: title
		)
		report
	end

	def note
		other
	end

	def target
		source
	end

	def link
		"/admin/reports/#{id}"
	end

	def write(msg)
		self.other << "<br>#{msg}"
	end

	def status
		resolved.nil? ? "Open" : resolved ? "Resolved" : "Closed"
	end

	def source_label
		first == "duplicate" ? "Target Video" : "Source"
	end

	def open?
		self.resolved.nil?
	end

	def icon
		'/favicon.ico'
	end

	def preview
		comment_thread.title
	end

	def change_status(sender, state)
		status = STATE_TO_STATUS[state]

		if self.resolved != status[1]
			self.resolved = status[1]
			send_update_notification("Report <b>#{comment_thread.title}</b> has been #{status[0]}")
		end

		self.resolved
	end

	def send_update_notification(message)
		save!
    Notification.send_to_admins(
      notification_params: {
        message: message,
        location: link,
        originator: comment_thread
      },
      toast_params: {
        title: 'Update from report',
        params: {
          badge: '/favicon.ico',
          icon: '/favicon.ico',
          body: message
        }
    })
	end
end
