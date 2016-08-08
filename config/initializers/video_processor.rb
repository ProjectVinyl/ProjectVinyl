class VideoProcessor
  @@flag = true
  @@master = nil
  
  @@Processors = []
  @@Workings = []
  @@SleepIncriment = 15
  @@SleepTimer = 0
  
  def self.status
    result = "<div>Control flag: " + @@flag.to_s + "</div>"
    result = result + "<div>Videos in queue: " + VideoProcessor.queue.length.to_s + "</div>"
    result = result + "<div>Master id: " + (@@master.nil? ? "None" : @@master.status.to_s) + "</div>"
    result = result + "<div>Workers: " + @@Processors.length.to_s + "</div>"
    @@Processors.each_with_index do |thread,index|
      result = result + '<div>Thread #' + index.to_s + ", status: " + thread.status.to_s + ", message: " + @@Workings[index].to_s + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if !video.checkIndex && @@master.status
      puts "[Processing Manager] Enqueued video"
    end
  end
  
  def self.queue
    return Video.where(processed: nil).order(:id)
  end
  
  def self.dequeue
    return VideoProcessor.queue.first
  end
  
  def self.processor(id)
    return Thread.start {
      begin
        puts "[Processing Manager] Spinning thread #(" + id.to_s + ")"
        while @@flag
          if video = VideoProcessor.dequeue()
            @@SleepTimer = 0
            @@Workings[id] = "Current video id:" + video.id.to_s + " (working)"
            video.generateWebM_sync
            @@Workings[id] = "Waiting"
          else
            @@SleepTimer = @@SleepTimer + @@SleepIncriment
            sleep(@@SleepTimer)
          end
        end
      rescue Exception => e
        puts "[Processing Manager] Thread died #(" + index.to_s + ")"
        puts e
        puts e.backtrace
      ensure
        ActiveRecord::Base.connection.close
        @@Workings[id] = "Shut down"
      end
    }
  end
  
  def self.stopMaster
    @@flag = false
  end
  
  def self.startManager
    puts "[Processing Manager] Attempting Master thread start"
    if @@master && @@master.status
      return
    end
    puts "[Processing Manager] Starting Master..."
    @@master = Thread.start {
      begin
        puts "[Processing Manager] Master Started"
        while @@flag
          while @@Processors.length < 2
            @@Workings << nil
            @@Processors << VideoProcessor.processor(@@Processors.length)
          end
          @@Processors.each_with_index do |thread,index|
            if thread.status == false
              @@Processors[index] = VideoProcessor.processor(index)
            end
          end
        end
      rescue Exception => e
        puts e
        puts e.backtrace
      ensure
        ActiveRecord::Base.connection.close
        @@master = nil
        @@flag = false
        puts "[Processing Manager] Master Shutting Down"
      end
    }
  end
end

VideoProcessor.startManager