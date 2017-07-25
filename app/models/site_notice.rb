class SiteNotice < ApplicationRecord
  def set_message(text)
    text = ApplicationHelper.demotify(text)
    self.message = text
    self.html_message = ApplicationHelper.emotify(text)
  end
end
