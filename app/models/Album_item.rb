class AlbumItem < ActiveRecord::Base
  belongs_to :album
  belongs_to :video
end