class OcTags < ActiveRecord::Migration
  def change
    TagType.create([
      { prefix: "oc" },
      { prefix: "spoiler" }
    ])
    oc = Tag.create({
      description: "Tag for any character that has not appeared in official media or merchandise; that is, a fan-made character, regardless of how popular they may be.",
      tag_type_id: 0
    }).set_name('oc')
    spoiler = Tag.create({
      description: "",
      tag_type_id: 0
    }).set_name('spoiler')
    TagTypeImplication.create([
      { tag_type_id: 3, implied_id: oc.id },
      { tag_type_id: 4, implied_id: spoiler.id }
    ])
  end
end
