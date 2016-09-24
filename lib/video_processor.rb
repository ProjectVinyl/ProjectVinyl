class ProcessingWorker < ActiveRecord::Base
  belongs_to :video
  
  def initialize
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
      self.message = "Shut Down"
      if @e
        self.message << " Error: " + @e.to_s + "<br>" + e.backtrace
      end
    end
    self.running = false
    self.status = "stopped"
    self.save
  end
  
  def zombie?
    return self.running && !self.video_id.nil? && !File.exists?(Rails.root.join('encoding', self.video_id.to_s + '.webm'))
  end
  
  def start
    puts "[Processing Manager] Spinning thread #(" + self.id.to_s + ")"
    while (video = VideoProcessor.dequeue())
      self.video_id = video.id
      self.update_status("running", "Current video id:" + video.id.to_s + " (working)")
      video.generateWebM_sync
      self.update_status("running", "Waiting")
    end
  end
  
  def exception=(e)
    @e = e
    puts "[Processing Manager] Thread died #(" + self.id.to_s + ")"
    puts @e
    puts @e.backtrace
  end
end

class VideoProcessor
  @@required_worker_count = 2
  
  def self.status
    workers = ProcessingWorker.all
    result = "<div>Videos in queue: " + VideoProcessor.queue.count.to_s + "</div>"
    result << "<div>Workers: " + workers.length.to_s + "</div>"
    workers.each do |worker|
      result << '<div>Thread #' + worker.id.to_s + ", status: " + worker.status + ", message: " + worker.message + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if !video.checkIndex
      puts "[Processing Manager] Enqueued video #" + video.id.to_s
      VideoProcessor.startManager
    end
  end
  
  def self.queue
    return Video.where(processed: nil, hidden: false).order(:id)
  end
  
  def self.dequeue
    result = nil
    begin
      ActiveRecord::Base.connection.execute('SELECT GET_LOCK("processor", 300);')
      if result = VideoProcessor.queue.first
        result.processed = false
        result.save
      end
    ensure
      ActiveRecord::Base.connection.execute('SELECT RELEASE_LOCK("processor");')
    end
    return result
  end
  
  def self.processor(db_object)
    if db_object && db_object.running
      return
    end
    if db_object
      db_object.update_status("running", "Ready")
    else
      db_object = ProcessingWorker.create(running: true, status: "running", message: "Ready")
    end
    Thread.start {
      begin
        db_object.start()
      rescue Exception => e
        db_object.exception = e
      ensure
        db_object.stop()
        ActiveRecord::Base.connection.close
      end
    }
  end
  
  def self.startManager
    puts "[Processing Manager] Attempting Master thread start"
    started_any = false
    result = 0
    count = ProcessingWorker.all.count
    while count < @@required_worker_count
      VideoProcessor.processor(nil)
      started_any = true
      count += 1
      result += 1
    end
    ProcessingWorker.where(running: true).each do |i|
      if i.zombie?
        i.running = false
        Video.where(id: i.video_id).update(processed: true)
        VideoProcessor.processor(i)
        started_any = true
        result += 1
      end
    end
    ProcessingWorker.where(running: false).each do |i|
      if result < @@required_worker_count
        VideoProcessor.processor(i)
        started_any = true
      end
      result += 1
    end
    return started_any
  end
end
