PID='/tmp/dat.pid'

God.watch do |w|
  w.name = "dat"
  w.start = "#{ENV["HOME"]}/Code/src/dat/bin/dat #{PID}"
  w.stop = "kill `cat #{PID}`"
  w.interval = 60.seconds
  w.start_grace = 5.seconds
  w.restart_grace = 5.seconds
  w.pid_file = PID

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 60.seconds
      c.running = false
    end
  end
end
