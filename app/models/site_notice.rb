class SiteNotice < ApplicationRecord
  def set_message(text)
    self.message = text
    self.html_message = BbcodeHelper.emotify(text)
  end
end
