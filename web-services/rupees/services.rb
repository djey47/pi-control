# services.rb - REST http server

require 'sinatra/base'
require 'json'
require 'logger'

class Services < Sinatra::Base
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    super #Required for correct Sinatra init
  end

  #config
  set :port, 4600
  set :show_exceptions, true
  set :environment, :development

  #Heartbeat
  get '/' do
    @logger.info('[Services] Heartbeat!')
    [200, 'pi-control - webservices are alive :)']
  end
end