#!/usr/local/rvm/bin/rvm-auto-ruby
require 'streamio-ffmpeg'
require 'net/http'
require 'httparty'
class NhkDownloader
  STREAM_1080_URL = "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp-en/index_4M.m3u8"
  #STREAM_1080_URL = "https://nhkwlive-xjp.akamaized.net/hls/live/2003458/nhkwlive-xjp-en/index_2M.m3u8"
  #STREAM_1080_URL = "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp/index_4M.m3u8"
  # def initialize(filepath, duration)
  #     FFMPEG::Movie.new(STREAM_1080_URL).transcode(filepath,  :duration=>duration)
  # end
  #
  
  def download_stream(filepath, duration)
    FFMPEG::Movie.new(STREAM_1080_URL).transcode(filepath,  :duration=>duration)
    outputname = filepath.gsub(/ts$/, 'mkv')
    system("HandBrakeCLI", "--preset", 'H.265 MKV 1080p30', "-i", filepath, "-o", outputname, :out => File::NULL)
    File.delete(filepath)
  end
end


# log = open("/media/storage/streamcap/log.txt", "wb")
# begin
#   downloader = NhkDownloader.new
#   j = downloader.get_schedule
#   title = j['channel']['item'].first['title']
#   response = HTTParty.get("https://nwapi.nhk.jp/nhkworld/epg/v7b/world/now.json")
#   j = JSON.parse(response.body)
#   title = j['channel']['item'].first['title']
#   log.puts "[#{DateTime.now.strftime("%Y%m%d %H:%m")}] #{j.inspect}"
#   if title.match?(/lunch|bento expo|oishii|pythagora|journeys in japan|view of japan/i)
#     log.puts "[#{DateTime.now.strftime("%Y%m%d %H:%m")}]  parsing #{title}"
#     title_part =  [j['channel']['item'][0]['title'], j['channel']['item'][0]['subtitle']].select {|s| s.match?(/[A-z]|[0-9]/)}.join(" ").gsub(/\"|\//,'')
#     if Dir.entries('/media/storage/streamcap').select {|s| s.match?(/#{title_part}/i)}.empty?
#       title =  [j['channel']['item'][0]['title'], j['channel']['item'][0]['subtitle'], Date.today.strftime('%Y%m%d'), "WEBDL-1080p"].select {|s| s.match?(/[A-z]|[0-9]/)}.join(" ").gsub(/\"|\//,'').gsub(':','')
#       log.puts "[#{DateTime.now.strftime("%Y%m%d %H:%m")}]  recording #{title}"
#       filename = "#{File.expand_path(File.dirname(__FILE__) + '/' + title)}.ts"
#       end_time = Time.at((j['channel']['item'].first['endDate'].to_i / 1000)+30)
#       downloader.download_stream(filename, (end_time - Time.now))
#       outputname = filename.gsub(/ts$/, 'mkv')
#       system("HandBrakeCLI", "--preset", 'H.265 MKV 1080p30', "-i", filename, "-o", outputname, :out => File::NULL)
#       File.delete(filename)
#     end
#     log.close
#   end
# rescue Exception=>e
#   log.puts e.message
#   log.puts e.backtrace
# ensure
#   log.close
# end
