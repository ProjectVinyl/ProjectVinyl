module Titled
  extend ActiveSupport::Concern
  
  included do
    validates :title, presence: true
    before_validation :validate_title, if: :will_save_change_to_title?
  end

  private
  def validate_title
    self.title = StringsHelper.check_and_trunk(title, title_was || "Untitled " + self.class.to_s)
    self.safe_title = PathHelper.url_safe(title)
    if respond_to?(:comment_thread) && comment_thread
      comment_thread.title = title
      comment_thread.save
    end
  end
end
