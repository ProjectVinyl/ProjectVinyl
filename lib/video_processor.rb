class ProcessingWorker < ActiveRecord::Base
  def update_status(s)
    if self.status != s
      self.running = true
      self.status = s
      self.save
    end
  end
  
  def stop
    self.running = false
    self.message = "Shut Down"
    self.update_status("stopped")
  end
  
  def start
    self.message = "Waiting"
    self.save
  end
end

class VideoProcessor
  @@flag = true
  @@master = nil
  
  @@Processors = []
  @@SleepIncriment = 15
  @@SleepTimer = 0
  
  def self.status
    workers = ProcessingWorker.all
    result = "<div>Control flag: " + @@flag.to_s + "</div>"
    
    result << "<div>Videos in queue: " + VideoProcessor.queue.length.to_s + "</div>"
    
    result = result + "<div>Workers: " + workers.length.to_s + "</div>"
    workers.each do |worker|
      result << '<div>Thread #' + worker.id.to_s + ", status: " + worker.status + ", message: " + worker.message + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if !video.checkIndex && @@master && @@master.status
      puts "[Processing Manager] Enqueued video #" + video.id
    end
  end
  
  def self.queue
    return Video.where(processed: nil).order(:id)
  end
  
  def self.dequeue
    return VideoProcessor.queue.first
  end
  
  def self.processor(id)
    db_object = ProcessingWorker.where(id: id).first
    if db_object && db_object.running
      return
    end
    if !db_object
      db_object = ProcessingWorker.create(id: id, running: true, status: "running", message: "Waiting")
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
            @@SleepTimer = @@SleepTimer + @@SleepIncriment
            sleep(@@SleepTimer)
          end
        end
      rescue Exception => e
        db_object.stop()
        puts "[Processing Manager] Thread died #(" + index.to_s + ")"
        puts e
        puts e.backtrace
      ensure
        ActiveRecord::Base.connection.close
      end
    }
  end
  
  def self.stopMaster
    @@flag = false
  end
  
  def self.startManager
    puts "[Processing Manager] Attempting Master thread start"
    if ProcessingWorker.where(running: true).length > 0
      return false
    end
    puts "[Processing Manager] Starting Master..."
    @@master = Thread.start {
      begin
        puts "[Processing Manager] Master Started"
        while @@flag
          while @@Processors.length < 2
            @@Processors << VideoProcessor.processor(@@Processors.length + 1)
          end
          @@Processors.each_with_index do |thread,index|
            if thread && thread.status == false
              @@Processors[index] = VideoProcessor.processor(index)
            end
          end
        end
      rescue Exception => e
        puts e
        puts e.backtrace
      ensure
        @@master = nil
        @@flag = false
        ProcessingWorker.update_all(running: false, message: "Shut Down", status: "stopped")
        ActiveRecord::Base.connection.close
        puts "[Processing Manager] Master Shutting Down"
      end
    }
    return true
  end
end
