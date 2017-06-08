class VideoProcessor
  @@required_worker_count = 2

  def self.status
    workers = ProcessingWorker.all
    result = "<div>Videos in queue: " + VideoProcessor.queue.count.to_s + "</div>"
    result << "<div>Workers: " + workers.length.to_s + "</div>"
    workers.each do |worker|
      result << '<div>Thread #' + worker.id.to_s + ", status: " + worker.status + ", message: " + worker.message + '</div>'
    end
    result
  end

  def self.enqueue(video)
    if !video.check_index
      puts "[Processing Manager] Enqueued video #" + video.id.to_s
      VideoProcessor.start_manager
    end
  end

  def self.queue
    Video.where(processed: nil, hidden: false).order(:id)
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
    result
  end

  def self.processor(db_object)
    return if db_object && db_object.running
    if db_object
      db_object.update_status("running", "Ready")
    else
      db_object = ProcessingWorker.create(running: true, status: "running", message: "Ready")
    end
    Thread.start do
      begin
        db_object.start
      rescue Exception => e
        db_object.exception = e
      ensure
        db_object.stop
        ActiveRecord::Base.connection.close
      end
    end
  end

  def self.start_manager
    started = 0
    result = 0
    count = ProcessingWorker.all.count
    while count < @@required_worker_count
      VideoProcessor.processor(nil)
      started_any = true
      count += 1
      result += 1
    end
    ProcessingWorker.where('running = true AND updated_at < ?', DateTime.now - 5.minutes).each do |i|
      next unless i.zombie?
      i.running = false
      Video.where(id: i.video_id).update_all(processed: true)
      VideoProcessor.processor(i)
      result += 1
      started += 1
    end
    ProcessingWorker.where(running: false).each do |i|
      break if result >= @@required_worker_count
      VideoProcessor.processor(i)
      result += 1
      started += 1
    end
    started
  end
end
