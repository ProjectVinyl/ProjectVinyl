module TimeHelper

  def since(date)
    "#{time_ago_in_words localise date} ago"
  end

  def current_time_zone
    return current_user.time_zone if current_user
    Time.zone
  end

  def localise(date)
    return date if date.nil?
    date.in_time_zone current_time_zone
  end

  def localise_ftime(date)
    localise(date).to_time.strftime('%e %B %Y at %H:%m:%S')
  end
end
