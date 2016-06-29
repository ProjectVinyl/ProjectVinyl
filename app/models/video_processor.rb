class VideoProcessor
  @@flag = true
  @@master = nil
  
  ProcessingQueue = Queue.new
  Processors = []
  
  def self.status
    result = "<div>Videos in queue: " + ProcessingQueue.length.to_s + "</div>"
    result = result + "<div>Workers: " + Processors.length.to_s + "</div>"
    Processors.each_with_index do |index,thread|
      result = result + '<div>Thread #' + index.to_s + " " + thread.status.to_s + '</div>'
    end
    return result
  end
  
  def self.enqueue(video)
    if !@@master
      VideoProcessor.startManager
    elsif @@master.status == 'sleeping'
      @@master.wakeup
    end
    ProcessingQueue.push(video)
    puts "[Processing Manager] Enqueued video"
  end
  
  def self.processor
    return Thread.start {
      while true
        ProcessingQueue.pop().generateWebM_sync
      end
    }
  end
    
  def self.startManager
    puts "[Processing Manager] Starting Master..."
    @@master = Thread.start {
      puts "[Processing Manager] Master Started"
      while true
        while Processors.length < 8
          puts "[Processing Manager] Spinning thread #(" + Processors.length.to_s + ")"
          Processors << VideoProcessor.processor
        end
        Processors.each_with_index do |index,thread|
          if !thread.status
            puts "[Processing Manager] Thread died #(" + index.to_s + ")"
            Processors[index] = VideoProcessor.processor
          end
        end
        break if @@flag == false
      end
    }
  end
end