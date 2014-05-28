require 'socket'
require 'open3'

OSRM_ROUTED_LOG_FILE = 'osrm-routed.log'

class OSRMLoader
  @@pid = nil
  
  def self.load input_file, &block
    @input_file = input_file
    Dir.chdir TEST_FOLDER do
      self.launch unless @@pid
      self.load_data
      yield
    end
  end
  
  def self.load_data
    puts "=== running osrm-datastore"
    puts "Time before running osrm-datastore: #{Time.now.to_f}"
    self.osrm_up?
    `#{BIN_PATH}/osrm-datastore #{@input_file}`
    puts "Time after running osrm-datastore:  #{Time.now.to_f}"
  end

  def self.launch
    Timeout.timeout(LAUNCH_TIMEOUT) do
      self.osrm_up
      self.wait_for_connection
    end
  rescue Timeout::Error
    raise RoutedError.new "Launching osrm-routed timed out."
  end

  def self.shutdown
    Timeout.timeout(SHUTDOWN_TIMEOUT) do
      self.osrm_down
    end
  rescue Timeout::Error
    self.kill
    raise RoutedError.new "Shutting down osrm-routed timed out."
  end

  def self.osrm_up?
    if @@pid
      s = `ps -o state -p #{@@pid}`.split[1].to_s.strip
      up = (s =~ /^[DRST]/) != nil
 #     puts "=== osrm-routed, status pid #{@@pid}: #{s} (#{up ? 'up' : 'down'})"
      up
    else
      false
    end
  end

  def self.osrm_up
    return if self.osrm_up?
    puts "=== launching osrm-routed"
    puts "Time before starting osrm-routed:   #{Time.now.to_f}"
    @@pid = Process.spawn("#{BIN_PATH}/osrm-routed --sharedmemory=1 --port #{OSRM_PORT}",:out=>OSRM_ROUTED_LOG_FILE, :err=>OSRM_ROUTED_LOG_FILE)
    puts "Time after starting osrm-routed:    #{Time.now.to_f}"
  end

  def self.osrm_down
    if @@pid
    puts '=== shutting down osrm'
      Process.kill 'TERM', @@pid
      self.wait_for_shutdown
    end
  end

  def self.kill
    if @@pid
      puts '=== killing osrm'
      Process.kill 'KILL', @@pid
    end
  end

  def self.wait_for_connection
    while true
      begin
        socket = TCPSocket.new('localhost', OSRM_PORT)
        return
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end
  end

  def self.wait_for_shutdown
    while self.osrm_up?
      sleep 0.1
    end
  end
end
