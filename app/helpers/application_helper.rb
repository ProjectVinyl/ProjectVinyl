module ApplicationHelper
  include IconsHelper, BbcodeHelper
  include PathHelper
  include ValuesHelper, FormatsHelper, StringsHelper, TimeHelper
  include FiltersHelper, VideoCacheHelper
  include ThemesHelper
  include PlaylistHelper
  

  def self.read_only
    ApplicationSettings.get(:read_only)
  end

  def read_only
    ApplicationHelper.read_only
  end

  def self.bg_ponies
    ApplicationSettings.get(:bg_ponies)
  end

  def bg_ponies
    ApplicationHelper.bg_ponies
  end
end
