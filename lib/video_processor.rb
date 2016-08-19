class ProcessingWorker < ActiveRecord::Base
  def update_status(s)
    if self.status != s
      self.running = true
      self.status = s
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
    result << "<div>Videos in queue: " + VideoProcessor.queue.length.to_s + "</div>"
    result << "<div>Workers: " + workers.length.to_s + "</div>"
    workers.each do |worker|
      result << '<div>Thread #' + worker.id.to_s + ", status: " + worker.status + ", message: " + worker.message + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if !video.checkIndex && @@master && @@master.status
      puts "[Processing Manager] Enqueued video #" + video.id
      ProcessingManager.startManager
    end
  end
  
  def self.queue
    return Video.where(processed: nil).order(:id)
  end
  
  def self.dequeue
    return VideoProcessor.queue.first
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
        puts "[Processing Manager] Spinning thread #(" + id.to_s + ")"
        while @@flag
          if video = VideoProcessor.dequeue()
            db_object.update_status("running")
            @@SleepTimer = 0
            db_object.message = "Current video id:" + video.id.to_s + " (working)"
            db_object.save
            video.generateWebM_sync
            db_object.message = "Waiting"
            db_object.save
          else
            db_object.update_status("sleep")
            if @@sleepTimer < 3600
              @@SleepTimer = @@SleepTimer + @@SleepIncriment
            end
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
    result = 0
    count = ProcessingWorker.all.count
    while count < @@required_worker_count
      VideoProcessor.processor(nil)
      count += 1
      result += 1
    end
    ProcessingWorker.where(running: false).each do |i|
      if result < @@required_worker_count
        VideoProcessor.processor(i)
      end
      result += 1
    end
    return result
  end
end
