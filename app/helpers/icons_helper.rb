module IconsHelper
  def bool(value)
    value ? "Yes" : "No"
  end
  
  def format_bg(link)
    "background-image: url('#{link}')"
  end
  
  def fa(icon)
    raw "<i class=\"fa fa-#{icon.to_s.gsub('_', '-')}\"></i>"
  end
  
  def fw(icon)
    fa "fw fa-#{icon}"
  end
  
  def fl(icon)
    fw "fl fa-#{icon}"
  end
end
