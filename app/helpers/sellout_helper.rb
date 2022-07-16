module SelloutHelper
  SELLOUTS = [
    {
      key: :aj,
      attribution: {
        source: '//derpibooru.org/549114',
        text: 'Image by zztfox'
      },
      messages: [
        "Pssst... Did you know that Project Vinyl is a community effort? We don't make any money off of this. But servers don't run on apples...",
        "If you like what you see, maybe you should consider donating to keep this site running?"
      ]
    },
    {
      key: :derpy,
      attribution: {
        source: '//derpibooru.org/694411',
        text: 'Image by zztfox'
      },
      messages: [
        "A muffin a day keeps the derpy at bay",
        "Project Vinyl is intirely non-profit, but if you like what you see please support us so we can keep going"
      ]
    },
    {
      key: :tpa,
      attribution: {
        source: '//derpibooru.org/images/5458',
        text: 'Image by atryl'
      },
      messages: [
        "Sponsored by The Pony Archive"
      ]
    },
    {
      key: :scoots,
      attribution: {
        source: '//derpibooru.org/images/561225',
        text: 'Image by zztfox'
      },
      messages: [
        "..."
      ]
    },
    {
      key: :boppy,
      attribution: {
        source: '//derpibooru.org/images/368959',
        text: 'Image by zztfox'
      },
      messages: [
        "I bet you thought this was an ad, didn't you?"
      ]
    }
  ]

  def random_sellout
    pick_one(SELLOUTS)
  end

  def pick_one(options)
    options[rand(options.length)]
  end
end
