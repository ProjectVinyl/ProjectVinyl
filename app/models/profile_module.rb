class ProfileModule < ApplicationRecord
  include Reorderable

  LEFT = 0
  RIGHT = 1
  DEFAULT_LEFT = [ :description, :art, :favourites, :recently_watched, :uploads, :albums ]
  DEFAULT_RIGHT = [ :comments ]

  belongs_to :user

  has_siblings :column_items

  scope :left_column, -> { where(column: LEFT).order(:index) }
  scope :right_column, -> { where(column: RIGHT).order(:index) }

  def self.seed(user)
    user.profile_modules.destroy
    l = DEFAULT_LEFT.each_with_index.map do |t, i|
      { user: user, column: LEFT, index: i, module_type: t}
    end
    r = DEFAULT_RIGHT.each_with_index.map do |t, i|
      { user: user, column: RIGHT, index: i, module_type: t}
    end
    ProfileModule.create l
    ProfileModule.create r
  end

  def column_name
    column == LEFT ? :left : :right
  end

  private
  def column_items
    user.profile_modules.where(column: column)
  end
end
