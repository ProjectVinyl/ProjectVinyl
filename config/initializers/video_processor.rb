class VideoProcessor
  @@flag = true
  @@master = nil
  
  V_QUEUE = Queue.new
  @@Processors = []
  @@Workings = []
  
  def self.status
    result = "<div>Control flag: " + @@flag.to_s + "</div>"
    result = result + "<div>Videos in queue: " + V_QUEUE.length.to_s + "</div>"
    result = result + "<div>Master id: " + (@@master.nil? ? "None" : @@master.status.to_s) + "</div>"
    result = result + "<div>Workers: " + @@Processors.length.to_s + "</div>"
    @@Processors.each_with_index do |thread,index|
      result = result + '<div>Thread #' + index.to_s + ", status: " + thread.status.to_s + ", message: " + @@Workings[index].to_s + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if video.checkIndex
      puts "[Processing Manager] Skipping #" + video.id.to_s + " existing webm found."
    end
    V_QUEUE.push(video)
    puts "[Processing Manager] Enqueued video"
  end
  
  def self.processor(id)
    return Thread.start {
      begin
        puts "[Processing Manager] Spinning thread #(" + id.to_s + ")"
        while @@flag
          video = V_QUEUE.pop()
          @@Workings[id] = "Current video id:" + video.id.to_s + " (working)"
          video.generateWebM_sync
          @@Workings[id] = "Waiting"
        end
      rescue Exception => e
        puts "[Processing Manager] Thread died #(" + index.to_s + ")"
        puts e
        puts e.backtrace
      ensure
        ActiveRecord::Base.connection.close
        @@Workings[id] = "Shut down"
        if @@flag
          @@Processors[id] = VideoProcessor.processor(id)
        end
      end
    }
  end
  
  def self.stopMaster
    @@flag = false
  end
  
  def self.startManager
    puts "[Processing Manager] Attempting Master thread start"
    if @@master
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