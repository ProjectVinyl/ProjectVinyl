class ProcessingWorker < ActiveRecord::Base
  def update_status(s, m)
    if !self.running || self.status != s || self.message != m
      self.running = true
      self.status = s
      self.message = m
      self.save
    end
  end
  
  def stop()
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
  
  def start
    self.message = "Waiting"
    self.save
  end
  
  def exception=(e)
    @e = e
  end
end

class VideoProcessor
  @@flag = true
  @@required_worker_count = 2
  @@SleepIncriment = 15
  @@SleepTimer = 0
  
  def self.status
    workers = ProcessingWorker.all
    result = "<div>Control flag: " + @@flag.to_s + "</div>"
    result << "<div>Videos in queue: " + VideoProcessor.queue.count.to_s + "</div>"
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
    ActiveRecord::Base.connection.execute('SELECT GET_LOCK("processor", 300);')
    result = VideoProcessor.queue.first
    result.processed = false
    result.save
    ActiveRecord::Base.connection.execute('SELECT RELEASE_LOCK("processor");')
    return result
  end
  
  def self.processor(db_object)
    if db_object && db_object.running
      return
    end
    if !db_object
      db_object = ProcessingWorker.create(running: true, status: "running", message: "Waiting")
    else
      db_object.start
    end
    return Thread.start {
      begin
        puts "[Processing Manager] Spinning thread #(" + db_object.id.to_s + ")"
        while @@flag
          if video = VideoProcessor.dequeue()
            @@SleepTimer = 0
            db_object.update_status("running", "Current video id:" + video.id.to_s + " (working)")
            video.generateWebM_sync
            db_object.update_status("running", "Waiting")
          else
            if @@sleepTimer < 3600
              @@SleepTimer = @@SleepTimer + @@SleepIncriment
            end
            db_object.update_status("sleep", "Wake up in " + @@SleepTimer + " seconds")
            sleep(@@SleepTimer)
          end
        end
      rescue Exception => e
        db_object.exception = e
        puts "[Processing Manager] Thread died #(" + index.to_s + ")"
        puts e
        puts e.backtrace
      ensure
        db_object.stop(nil)
        ActiveRecord::Base.connection.close
      end
    }
  end
  
  def self.stopMaster
    @@flag = false
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
