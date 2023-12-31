require 'logger'
require 'fileutils'
require_relative 'nhk_cache'
require_relative 'nhk_downloader'

class NhkListener
  attr_reader :options, :quit, :schedule, :episodes_to_grab
  
  NHK_SCHEDULE_URL = 'https://nwapi.nhk.jp/nhkworld/epg/v7b/world/now.json'
  SHOW_TITLE_REGEXP = /lunch|bento expo|oishii|pythagora|journeys in japan|view of japan/i
  WORKING_DIRECTORY = ENV['NHK_DL_DIR'] || '/tmp'
  PIDFILE_PATH = ENV['NHK_PIDFILE'] || '/tmp/nhklistener.pid'
  LOGFILE_PATH = ENV['NHK_LOGFILE'] || '/tmp/nhklistener.log'
  
  def initialize(options={})
    @options = options
    options[:logfile] = File.expand_path(logfile)
    options[:pidfile] = File.expand_path(pidfile)
    $LOGGER = Logger.new(options[:logfile] || STDOUT)
    $LOGGER.level = options[:loglevel] || Logger::INFO
    $LOGGER.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} #{severity} #{msg}\n"
    end
    @episodes_to_grab = []
    $LOGGER.info "Starting #{self.class}..."
  end
  
  def daemonize?
    options[:daemonize] || ENV['DAEMONIZE']
  end
  
  def run!
    check_pid
    daemonize if daemonize?
    write_pid
    trap_signals
    redirect_output if daemonize?
    until quit
      schedule_episodes_to_grab
      capture_episode_if_playing
      sleep(5)
    end
  end
  
  def schedule
    @schedule = NhkCache.instance.get_cache(:nhk_schedule, 60*60) do
      response = HTTParty.get(NHK_SCHEDULE_URL)
      JSON.parse(response.body)
    end
  end
  
  def capture_episode_if_playing
    @episodes_to_grab.each do |episode|
      if episode[:start_time] <= Time.now && episode[:end_time] >= Time.now
        @episodes_to_grab.delete(episode)
        Thread.new do
          $LOGGER.info "Recording #{episode[:filename]}"
          downloader = NhkDownloader.new
          downloader.download_stream(episode[:filename], (episode[:end_time] - Time.now))
        end.join
      end
    end
  end
  
  def schedule_episodes_to_grab
    schedule['channel']['item'].each do |item|
      title = item['title']
      if title.match?(SHOW_TITLE_REGEXP)
        title_part =  [item['title'], item['subtitle']].select {|s| s.match?(/[A-z]|[0-9]/)}.join(" ").gsub(/\"|\//,'')
        if Dir.entries(WORKING_DIRECTORY).select {|s| s.match?(/#{title_part}/i)}.empty?
          title =  [item['title'], item['subtitle'], Date.today.strftime('%Y%m%d'), "WEBDL-1080p"].select {|s| s.match?(/[A-z]|[0-9]/)}.join(" ").gsub(/\"|\//,'').gsub(':','')
          next if @episodes_to_grab.any? {|e| e[:filename].match?(/#{title}/i)}
          filename = "#{File.expand_path(WORKING_DIRECTORY + '/' + title)}.ts"
          end_time = Time.at((item['endDate'].to_i / 1000)+30)
          start_time = Time.at(item['pubDate'].to_i / 1000)
          $LOGGER.info "Scheduling #{title} to record at #{start_time}"
          @episodes_to_grab << {:filename=>filename, :start_time=>start_time, :end_time=>end_time}
        end
      end
    end
  end
  
  
  def pidfile
    options[:pidfile] || PIDFILE_PATH
  end
  
  def logfile
    options[:logfile] || LOGFILE_PATH
  end
  
  def write_pid
    begin
      File.open(pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY){|f| f.write("#{Process.pid}") }
      at_exit { File.delete(pidfile) if File.exist?(pidfile) }
    rescue Errno::EEXIST
      check_pid
      retry
    end
  end
  
  def check_pid
    case pid_status(pidfile)
    when :running, :not_owned
      puts "A server is already running. Check #{pidfile}"
      exit(1)
    when :dead
      File.delete(pidfile)
    end
  end
  
  def pid_status(pidfile)
    return :exited unless File.exist?(pidfile)
    
    pid = ::File.read(pidfile).to_i
    return :dead if pid.zero?
    
    Process.kill(0, pid)      # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end
  
  def daemonize
    Process.daemon(true, true)
    # exit if fork
    # Process.setsid
    # exit if fork
    # Dir.chdir "/"
  end
  
  def redirect_output
    FileUtils.mkdir_p(File.dirname(logfile), :mode => 0755)
    FileUtils.touch logfile
    File.chmod(0644, logfile)
    $stderr.reopen(logfile, 'a')
    $stdout.reopen($stderr)
    $stdout.sync = $stderr.sync = true
  end
  
  def trap_signals
    trap(:QUIT) { @quit = true }
    trap(:TERM) { @quit = true }
    trap(:INT) { @quit = true }
  end
end

NhkListener.new.run!