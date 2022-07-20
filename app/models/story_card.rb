class StoryCard < ApplicationRecord
  belongs_to :video
  belongs_to :content, polymorphic: true

  def video?
    content_type == 'Video'
  end

  def user?
    content_type == 'User'
  end

  def custom?
    !video? && !user?
  end
  
  def variant
    return :video if video?
    return :user if user?
    :custom
  end

  def dimensions
    "--x:#{left}%;--y:#{top}%;--w:#{width}%;--h:#{height}%;"
  end

  def dimensions=(dimensions)
    ( self.left, self.top, self.width, self.height ) = dimensions
  end

  def duration=(duration)
    ( self.start_time, self.end_time ) = duration
  end

  def card_content
    if user?
      card = CardContent.new
      card.style = style
      card.title = content.username
      card.image = content.avatar
      card.url = content.link
      card.metadata = content.bio
      return card
    elsif video?
      card = CardContent.new
      card.style = style
      card.title = content.title
      card.image = content.cover
      card.url = content.link
      card.metadata = FormatsHelper.duration content.duration
      return card
    end

    self
  end

  def widget_parameters
    {
      style: style,
      start: start_time,
      end: end_time,
      card_id: id
    }
  end

  def self.for_user(user)
    card = StoryCard.new
    card.style = :channel
    card.content = user
    card.dimensions= [60, 40, 25, 25]
    card
  end

  def self.for_video(video)
    card = StoryCard.new
    card.style = :video
    card.content = video
    card.dimensions= [5, 20, 50, 50]
    card
  end

  class CardContent
    attr_accessor :style, :title, :image, :metadata, :url
  end
end
