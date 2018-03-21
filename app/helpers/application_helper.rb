module ApplicationHelper
  include IconsHelper
  include BbcodeHelper
  include PathHelper
  include ValuesHelper
  include FormatsHelper
  include StringsHelper
  
  def self.read_only
    false
  end
  
  def read_only
    ApplicationHelper.read_only
  end
end
