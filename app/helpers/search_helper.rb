module SearchHelper
  DERPS = [
    "That wasn't me, I swear! D:",
    "I just don't know what went wrong.",
    "Oops...My bad!",
    "Mmmmf umph mrrfff, ump mrfffn ferf.",
    "This is a demo, right?",
    "Muffin?"
  ].freeze

  NOT_FOUND_MESSAGES = [
    "I just couldn't find i anything!",
    "I'm sorry, I'll try harder next time.",
    "I kept looking, and looking, but there just wasn't anything there!"
  ].freeze

  EMPTY_VIDEO_FEED_MESSAGES = [
    'Sorry, your feed is empty. :(',
    "Nothing here but us derp",
    "I don't see anything here but I'll keep looking!"
  ].freeze

  EMPTY_SUBSCRIPTION_MESSAGES = [
    "I don't see anything here but I'll keep looking!",
    "Follow a user with a tag and you will see them here"
  ].freeze

  EMPTY_INBOX_MESSAGES = [
    'Nu-uh, no messages here',
    "Nothing here but us derp",
    "I don't see anything here but I'll keep looking!",
    "Your inbox may be empty but I still love you!"
  ].freeze

  def not_found_messages
    NOT_FOUND_MESSAGES
  end

  def empty_video_feed_messages
    EMPTY_VIDEO_FEED_MESSAGES
  end

  def empty_subscription_messages
    EMPTY_SUBSCRIPTION_MESSAGES
  end

  def empty_inbox_messages
    EMPTY_INBOX_MESSAGES
  end

  def derp
    pick_one(DERPS)
  end
end
