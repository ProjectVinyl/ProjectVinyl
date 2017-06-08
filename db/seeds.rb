Board.create([
  { id: 2, title: 'General', description: '' },
  { id: 9, title: 'Site and Policty', description: '' }
])
TagType.create([
  { id: 1, prefix: 'artist', hidden: 0 },
  { id: 2, prefix: 'genre', hidden: 0 },
  { id: 3, prefix: 'oc', hidden: 0 },
  { id: 4, prefix: 'spoiler', hidden: 0 },
  { id: 5, prefix: 'character', hidden: 1 }
])
TagTypeImplication.create([
  { id: 1, tag_type_id: 3, implied_id: 53 },
  { id: 2, tag_type_id: 4, implied_id: 54 }
])
Tag.create([
  {
    id: 1,
    name: 'genre:electro-pop',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:electro-pop',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 2,
    name: 'genre:dubstep',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:substep',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 3,
    name: 'genre:fusion',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:fusion',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 4,
    name: 'genre:world',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:world',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 5,
    name: 'genre:blues',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:blues',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 6,
    name: 'genre:classical',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:classical',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 7,
    name: 'genre:country',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:country',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 8,
    name: 'genre:electroswing',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:electroswing',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 9,
    name: 'genre:techno',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:techno',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 10,
    name: 'genre:easy listening',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:easy listening',
    video_count: 0,
    user_count: 1,
    alias_id: 0
  },
  {
    id: 11,
    name: 'genre:chiptune',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:chiptune',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 12,
    name: 'genre:industrial',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:industrial',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 13,
    name: 'genre:idm/experimental',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:idm/experimental',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 14,
    name: 'genre:hip-hop',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:hip-hop',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 15,
    name: 'genre:rap',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:rap',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 16,
    name: 'genre:holiday',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:holiday',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 17,
    name: 'genre:gospel',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:gospel',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 18,
    name: 'genre:instrumental',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:instrumental',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 19,
    name: 'genre:pop',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:pop',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 20,
    name: 'genre:jazz',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:jazz',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 21,
    name: 'genre:gypsy',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:gypsy',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 22,
    name: 'genre:rock',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:rock',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 23,
    name: 'genre:r&b/soul',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:r-b/soul',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 24,
    name: 'genre:reggae',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:reggae',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 25,
    name: 'genre:folk',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:folk',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 26,
    name: 'genre:soundtrack',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:soundtrack',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 27,
    name: 'genre:showtunes',
    description: 'Sweetie Belles favourite',
    tag_type_id: 2,
    short_name: 'genre:showtunes',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 28,
    name: 'genre:remix',
    description: '',
    tag_type_id: 2,
    short_name: 'genre:remix',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 30,
    name: 'artist:sollace',
    description: '',
    tag_type_id: 1,
    short_name: 'artist:sollace',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 31,
    name: 'twilight sparkle',
    description: '',
    tag_type_id: 5,
    short_name: 'twilight sparkle',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 32,
    name: 'pinkie pie',
    description: '',
    tag_type_id: 5,
    short_name: 'pinkie pie',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 33,
    name: 'artist:bob',
    description: '',
    tag_type_id: 1,
    short_name: 'artist:bob',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 34,
    name: 'smile',
    description: '',
    tag_type_id: 0,
    short_name: 'smile',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 35,
    name: 'remix',
    description: '',
    tag_type_id: 0,
    short_name: 'remix',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 36,
    name: 'artist:the living tombstone',
    description: 'A super awesome artist',
    tag_type_id: 1,
    short_name: 'artist:the living tombstone',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 37,
    name: 'wibbly',
    description: '',
    tag_type_id: 0,
    short_name: 'wibbly',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 38,
    name: 'this will give you diabetees',
    description: '',
    tag_type_id: 0,
    short_name: 'this will give you diabetees',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 39,
    name: 'gibberish in the comments',
    description: '',
    tag_type_id: 0,
    short_name: 'gibberish in the comments',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 40,
    name: 'smile song',
    description: '',
    tag_type_id: 0,
    short_name: 'smile song',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 41,
    name: 'smile hd',
    description: '',
    tag_type_id: 0,
    short_name: 'smile hd',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 42,
    name: 'c:',
    description: 'Smiley',
    tag_type_id: 0,
    short_name: 'c:',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 43,
    name: 'safe',
    description: 'Like a vault',
    tag_type_id: 0,
    short_name: 'safe',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 44,
    name: 'cute',
    description: '',
    tag_type_id: 0,
    short_name: 'cute',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 45,
    name: 'a friend in deed',
    description: '',
    tag_type_id: 0,
    short_name: 'a friend in deed',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 46,
    name: 'wobbly',
    description: '',
    tag_type_id: 0,
    short_name: 'wobbly',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 47,
    name: 'timey',
    description: '',
    tag_type_id: 0,
    short_name: 'timey',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 48,
    name: 'oc:lannie lona',
    description: '',
    tag_type_id: 3,
    short_name: 'oc:lannie lona',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 49,
    name: 'rainbow dash',
    description: '',
    tag_type_id: 5,
    short_name: 'rainbow dash',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 51,
    name: 'fluttershy',
    description: '',
    tag_type_id: 0,
    short_name: 'fluttershy',
    video_count: 0,
    user_count: 0,
    alias_id: 61
  },
  {
    id: 52,
    name: 'oc:bob',
    description: '',
    tag_type_id: 3,
    short_name: 'oc:bob',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 53,
    name: 'oc',
    description: 'Tag for any character that has not appeared in official media or merchandise; that is, a fan-made character, regardless of how popular they may be.',
    tag_type_id: 0,
    short_name: 'oc',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 54,
    name: 'wimey',
    description: '',
    tag_type_id: 0,
    short_name: 'wimey',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 55,
    name: 'artist:dr sample blank',
    description: '',
    tag_type_id: 1,
    short_name: 'artist:dr sample blank',
    video_count: 0,
    user_count: 0,
    alias_id: 30
  },
  {
    id: 56,
    name: 'oc:nom',
    description: '',
    tag_type_id: 3,
    short_name: 'oc:nom',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 57,
    name: 'blop',
    description: '',
    tag_type_id: 0,
    short_name: 'blop',
    video_count: 0,
    user_count: 0,
    alias_id: 45
  },
  {
    id: 58,
    name: 'boop',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'boop',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 59,
    name: 'tag',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'tag',
    video_count: 0,
    user_count: 0,
    alias_id: 64
  },
  {
    id: 60,
    name: 'hy',
    description: '',
    tag_type_id: 0,
    short_name: 'hy',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 61,
    name: 'gj',
    description: '',
    tag_type_id: 0,
    short_name: 'gj',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 62,
    name: 'sjnkl',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'sjnkl',
    video_count: 0,
    user_count: 0,
    alias_id: 34
  },
  {
    id: 63,
    name: 'dafsd',
    description: '',
    tag_type_id: 0,
    short_name: 'dafsd',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 64,
    name: 'test',
    description: '',
    tag_type_id: 0,
    short_name: 'test',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 65,
    name: 'dkmls',
    description: '',
    tag_type_id: 0,
    short_name: 'dkmls',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 66,
    name: 'c',
    description: '',
    tag_type_id: 0,
    short_name: 'c',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 67,
    name: 'artist:dr sample',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:dr sample',
    video_count: 0,
    user_count: 0,
    alias_id: 30
  },
  {
    id: 68,
    name: 'oc:somenewoc',
    description: '',
    tag_type_id: 3,
    short_name: 'oc:somenewoc',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 69,
    name: 'bob',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'bob',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 70,
    name: 'cheerilee',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'cheerilee',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 72,
    name: 'ghost busters',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'ghost busters',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 73,
    name: 'ghast',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'ghast',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 74,
    name: 'pompus',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'pompus',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 75,
    name: 'pompups',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'pompups',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 77,
    name: 'dr white',
    description: '',
    tag_type_id: 0,
    short_name: 'dr white',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 78,
    name: 'dr black',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'dr black',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 79,
    name: 'derpy',
    description: '',
    tag_type_id: 0,
    short_name: 'derpy',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 80,
    name: 'artist:blackgyph',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:blackgyph',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 81,
    name: 'artist:markimoo',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:markimoo',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 82,
    name: 'artist:artistmarkiplier',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:artistmarkiplier',
    video_count: 0,
    user_count: 0,
    alias_id: 83
  },
  {
    id: 83,
    name: 'artist:markiplier',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:markiplier',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 84,
    name: 'artist:jontronshow',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:jontronshow',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 85,
    name: 'artist needed',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'artist needed',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 86,
    name: 'source needed',
    description: '',
    tag_type_id: 0,
    short_name: 'source needed',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 87,
    name: 'spoiler:bob',
    description: '',
    tag_type_id: 4,
    short_name: 'spoiler:bob',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 88,
    name: 'featured video',
    description: '',
    tag_type_id: 0,
    short_name: 'featured video',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 89,
    name: 'artist:dj-pon3',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:dj-pon3',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 90,
    name: 'farmer john',
    description: '',
    tag_type_id: 0,
    short_name: 'farmer john',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 91,
    name: 'rainbow licious',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'rainbow licious',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 92,
    name: 'sosso',
    description: '',
    tag_type_id: 0,
    short_name: 'sosso',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 93,
    name: 'lyra',
    description: '',
    tag_type_id: 0,
    short_name: 'lyra',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 94,
    name: 'artist:blast beat',
    description: 'No description Provided',
    tag_type_id: 1,
    short_name: 'artist:blast beat',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 95,
    name: '[object object]',
    description: '',
    tag_type_id: 0,
    short_name: 'object object',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 96,
    name: 'rainbow bob',
    description: '',
    tag_type_id: 0,
    short_name: 'rainbow bob',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  },
  {
    id: 97,
    name: 'rarity',
    description: 'No description Provided',
    tag_type_id: 0,
    short_name: 'rarity',
    video_count: 0,
    user_count: 0,
    alias_id: 0
  }
])
TagImplication.create([
  { id: 1, tag_id: 52, implied_id: 53 },
  { id: 2, tag_id: 56, implied_id: 53 },
  { id: 6, tag_id: 36, implied_id: 53 },
  { id: 7, tag_id: 68, implied_id: 53 },
  { id: 8, tag_id: 45, implied_id: 64 },
  { id: 9, tag_id: 48, implied_id: 53 }
])
#User badges
Badge.create([
  { id: 1, title: 'Duck', colour: 'yellow', icon: 'duck', badge_type: 1 },
  { id: 2, title: 'Bronze Bit', colour: 'orange', icon: 'bit', badge_type: 0 },
  { id: 3, title: 'Silver Bit', colour: 'lightblue', icon: 'silverbit', badge_type: 0 },
  { id: 4, title: 'Gold Bit', colour: 'yellow', icon: 'goldbit', badge_type: 0 },
  { id: 5, title: 'Tom', colour: 'grey', icon: 'tom', badge_type: 0 },
  { id: 6, title: 'Gem', colour: 'white', icon: 'gem', badge_type: 0 }
])

# init Elasic-Search
Video.__elasticsearch__.create_index!
User.__elasticsearch__.create_index!

# No users are created
# To log in, create an account normally and activate/make it as an admin with the following:
# User.connection
# User.update_all('role = 3, confirmed_at = confirmation_sent_at, unconfirmed_email = NULL')