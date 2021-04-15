class SeedRatingTags < ActiveRecord::Migration[5.1]
  def tag_hash(type, name, desc)
    name = type.prefix + ':' + name
    Tag.create(
      name: name,
      description: desc,
      tag_type_id: type.id,
      short_name: name,
      video_count: 0,
      user_count: 0,
    ).id
  end

  def change
    rating = TagType.create(prefix: 'rating', hidden: 0)

    everyone = tag_hash(rating, 'everyone', 'Content suitable for all ages.')
    teen = tag_hash(rating, 'teen', 'Content suitable for teen (13+). Parental supervision advised')
    mature = tag_hash(rating, 'mature', 'Content suitable for adults (18+).')

    warning = TagType.create(prefix: 'warning', hidden: 0)

    suggestive = tag_hash(warning, 'suggestive', 'Minorly/implicitly sexual; innuendos, sexual references, groping, clothing showing a lot of bulge/boob/ass, etc.')
    questionable = tag_hash(warning, 'questionable', 'Sexual, but not explicit; nipples, squicky fetish acts, sexual acts that aren\'t actually sex, etc.')
    explicit = tag_hash(warning, 'explicit', 'Explicit sexual content – visible genitals, detailed genital/anus representations, sex, cum, etc.')
    grimdark = tag_hash(warning, 'grimdark', 'Nightmarish things like dying painfully and traumatic abuse.')
    grotesque = tag_hash(warning, 'grotesque', 'For the really gross/disturbing stuff like body horror, gore, filth and waste, etc.')

    TagRule.create([
      { any_of: [everyone, teen, mature], message: 'Image must have a rating tag'},
      { when_present: [everyone], none_of: [teen,mature], message: 'Only one rating tag per image'},
      { when_present: [teen], none_of: [everyone,mature], message: 'Only one rating tag per image'},
      { when_present: [mature], none_of: [everyone,teen], message: 'Only one rating tag per image'},
      { when_present: [everyone], none_of: [questionable,explicit,grimdark,grotesque,], message: 'Safe images should not have any content warnings above suggestive'},
    ])
    TagImplication.create([
      {tag_id: questionable, implied_id: teen},
      {tag_id: explicit, implied_id: mature},
      {tag_id: grimdark, implied_id: mature},
      {tag_id: grotesque, implied_id: mature}
    ])
    Video.in_batches do |videos|
      items = videos.pluck(:id).map do |id|
        { video_id: id, tag_id: everyone }
      end

      VideoGenre.create(items)
      videos.update_index
    end
  end
end
