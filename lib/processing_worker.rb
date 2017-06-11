class ProcessingWorker < ActiveRecord::Base
  belongs_to :video

  def initialize(*args)
    super(*args)
    @e = nil
  end

  def update_status(s, m)
    if !self.running || self.status != s || self.message != m
      self.running = true
      self.status = s
      self.message = m
      self.save
    end
  end

  def stop
    if self.running
      if self.video_id && self.video_id > 0
        puts "[Processing Manager] Thread Shutdown (forced) #(" + self.id.to_s + ")"
      else
        puts "[Processing Manager] Thread Shutdown #(" + self.id.to_s + ")"
      end
      self.message = "Shut Down"
      if @e
        self.message << " Error: " + @e.to_s + "<br>" + @e.backtrace
        puts "\t\t Error: " + @e.to_s + "\n" + @e.backtrace
      end
    end
    self.running = false
    self.status = "stopped"
    self.save
  end

  def zombie?
    self.running && !self.video.nil? && !File.exist?(Rails.root.join('encoding', self.video_id.to_s + '.webm')) && File.exist?(Rails.root.join('public', 'stream', self.video_id.to_s + '.webm'))
  end

  def start
    puts "[Processing Manager] Spinning thread #" + self.id.to_s
    while (video = VideoProcessor.dequeue)
      self.video_id = video.id
      self.update_status("running", "Current video id:" + video.id.to_s + " (working)")
      video.generate_webm_sync
      self.update_status("running", "Waiting")
    end
    self.video_id = 0
  end

  def exception=(e)
    @e = e
    puts "[Processing Manager] Thread died #(" + self.id.to_s + ")"
    puts @e
    puts @e.backtrace
  end
end
