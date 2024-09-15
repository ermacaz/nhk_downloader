require 'sinatra'
class ApiApp < Sinatra::Base
  set :port, 4567
  
  before do
    content_type :json
  end
  
  get '/schedule' do
    daemon = settings.daemon
    { status: 'running', schedule: daemon.schedule }.to_json
  end
  
  get '/scheduled_to_grab' do
    daemon = settings.daemon
    { status: 'running', schedule: daemon.episodes_to_grab }.to_json
  end
end