module PlaylistHelper
  def playlist_looping?
    cookies[:loop].to_i == 1
  end
  
  def playlist_shuffling?
    cookies[:shuffle].to_i == 1
  end

  def mark_seen(album, video)
    if !album || !playlist_shuffling?
      self.seen_videos = {} if seen_videos && seen_videos.include?('videos')
      return
    end

    self.seen_videos = {} if !seen_videos
    seen_videos['videos'] = [] if (seen_videos['album_id'] != album.id || !seen_videos.include?('videos'))
    seen_videos['album_id'] = album.id
    seen_videos['videos'] << video.id

    self.seen_videos = seen_videos
  end
  
  def video_seen?(video_id)
    seen_videos && seen_videos.include?('videos') && seen_videos['videos'].include?(video_id)
  end
  
  def seen_videos=(hash)
    @seen_videos = hash
    cookies[:shuffle_past_videos] = hash.to_json
  end
  
  def seen_videos
    @seen_videos || (@seen_videos = __load_seen_videos)
  end
  
  def __load_seen_videos
    json = cookies[:shuffle_past_videos]
    begin
      return JSON.parse(json) if json.present?
    rescue
      
    end
    
    {}
  end
end
