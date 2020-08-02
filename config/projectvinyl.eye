Eye.config do
  logger '/home/ubuntu/ProjectVinyl/log/eye.log'
end

resque_per_queue = 2
resque_queues = ['*', 'manual', 'high_priority']
resque_count = resque_per_queue * resque_queues.length

Eye.application 'ProjectVinyl' do
  working_dir '/home/ubuntu/ProjectVinyl'
  stdall '/home/ubuntu/ProjectVinyl/log/background.log'
  trigger :flapping, times: 10, within: 1.minute, retry_in: 10.minutes
  env 'RAILS_ENV' => ENV['RAILS_ENV'] || 'production'
  stop_on_delete true
  start_grace 10.seconds

  group 'resque' do
    chain grace: 2.seconds
    (1..resque_count).each do |i|
      process "resque-#{i}" do
        env 'QUEUE' => resque_queues[i/2]
        pid_file "tmp/pids/resque-#{i}.pid"
        daemonize true
        start_command "rake environment resque:work"
        stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
        stdall "log/resque-#{i}.log"
        check :memory, every: 20.seconds, below: 350.megabytes, times: 3
      end
    end
  end
end
