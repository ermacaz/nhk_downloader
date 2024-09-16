#!/usr/local/rvm/bin/rvm-auto-ruby
require 'streamio-ffmpeg'
require 'net/http'
require 'httparty'
class NhkDownloader
  # STREAM_1080_URL = "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp-en/index_4M.m3u8"
  #STREAM_1080_URL =   "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp-en/index_1M.m3u8"
  STREAM_1080_URL =  "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp-en/index_2M.m3u8"
  #STREAM_1080_URL = "https://nhkwlive-xjp.akamaized.net/hls/live/2003458/nhkwlive-xjp-en/index_2M.m3u8" #really 720
  #STREAM_1080_URL = "https://nhkwlive-ojp.akamaized.net/hls/live/2003459/nhkwlive-ojp/index_4M.m3u8"
  # def initialize(filepath, duration)
  #     FFMPEG::Movie.new(STREAM_1080_URL).transcode(filepath,  :duration=>duration)
  # end
  #
  
  def download_stream(filepath, duration)
    duration = 30
    options = {:duration=>duration,
      video_codec: "h264", frame_rate: 30, resolution: "1280x720", video_bitrate: 1500,
    x264_vprofile: "high", x264_preset: "slow",
      threads: 2
    }
    FFMPEG::Movie.new(STREAM_1080_URL).transcode(filepath,  options)
    # outputname = filepath.gsub(/ts$/, 'mkv')
    # system("HandBrakeCLI", "--preset", 'H.265 MKV 1080p30', "-i", filepath, "-o", outputname, :out => File::NULL)
    # File.delete(filepath)
  end
end

