class VirtualAlbumItem < AlbumItem
  def initialize(valbum, video, i)
    @album = valbum
    @video = video
    @index = i
  end

  def id
    0
  end

  attr_reader :album, :video, :index

  def video_id
    @video.id
  end

  def album_id
    @album.id
  end

  def user
    @album.user
  end

  def ref
    "q=#{self.album.query}&index=#{self.index}"
  end
end
