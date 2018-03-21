module SearchHelper
  DERPS = [
    "That wasn't me, I swear! D:",
    "I just don't know what went wrong.",
    "Oops...My bad!",
    "Mmmmf umph mrrfff, ump mrfffn ferf.",
    "This is a demo, right?",
    "Muffin?"
  ].freeze
  
  def derp
    DERPS.sample(1)[0]
  end
end
