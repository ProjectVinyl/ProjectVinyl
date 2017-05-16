class GenreAdminController < ApplicationController
  def view
    @types = TagType.includes(:tag_type_implications).all
  end
end
