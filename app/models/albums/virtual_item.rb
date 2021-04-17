module Albums
  class VirtualItem
    include Item

    attr_reader :album, :video, :user, :index, :ref
    attr_accessor :id, :video_id, :album_id

    def initialize(valbum, video, i)
      @id = 0
      @album = valbum
      @video = video
      @user = @album.user
      @index = i
      @album_id = @album.id
      @video_id = @video.id
      @ref = "q=#{@album.query}&index=#{i}"
    end
  end
end
