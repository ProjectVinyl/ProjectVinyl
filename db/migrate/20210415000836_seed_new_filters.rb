class SeedNewFilters < ActiveRecord::Migration[5.1]
  def change
    SiteFilter.create([
      { name: 'Default', description: 'The default filter. Hides mature content and spoilers fringe.',
        hide_tags: 'rating:mature,warning:questionable,warning:explicit,warning:grimdark,warning:grotesque',
        spoiler_tags: 'rating:teen,warning:suggestive',
        preferred: 1
      },
      { name: '18+', description: 'Displays erotic content whilst hiding dark and grotesque content.',
        hide_tags: 'warning:grimdark,warning:grotesque,rating:everyone', spoiler_tags: ''
      },
      { name: '18+ Dark', description: 'Displays dark and grotesque content whilst hiding non-erotic content.',
        hide_tags: 'rating:everyone', spoiler_tags: ''
      }
    ])
  end
end
