module ThemesHelper
  THEMES = %w[Light Dark]

  def current_theme
    cookies[:site_theme].to_i
  end

  def current_theme_name
    themes[current_theme].downcase
  end

  def themes
    THEMES
  end
end
