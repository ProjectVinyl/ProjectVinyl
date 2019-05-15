module ValuesHelper
  include IconsHelper

  # Sets a descriptive page title
  def title(page_title)
    content_for(:title) { page_title }
  end
  
  # Sets page content width
  def lim(page_width)
    content_for(:width) { page_width }
  end
  
  # Applies a class to the main content wrapper for the page
  def wrapper(wrapper_class)
    content_for(:wrapper) { wrapper_class }
  end

  # Applies a custom banner image to the main content
  def banner(banner_src)
    content_for(:custom_banner) { banner_src.html_safe }
  end
  
  # Gets the current search query
  def query
    @query || params[:tagquery] || params[:q]
  end
  
  # Gets the current search type
  def search_type
    params[:type].to_i
  end
  
  def load_time
    Time.now - @start_time
  end
  
  def email_escape(email)
    html_escape(email).gsub(/@/, fa(:at)).html_safe
  end
  
  # Gets current_user or an anonomous user
  def visitor
    @visitor ||= user_signed_in? ? current_user : UserAnon.new(session)
  end
end
