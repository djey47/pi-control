# services.rb - REST http server

require 'logger'
require 'sinatra/base'
require 'yaml'
require_relative 'system_gateway'

class Services < Sinatra::Base

  # To inject different gateways (real and mock)
  def initialize(system_gateway = SystemGateway.new)
    @system_gateway = system_gateway
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    super #Required for correct Sinatra init
  end

  def esxi_off
    @logger.info('[Services][esxi_off]')

    begin
      contents = YAML.load_file('../conf/pi-control.yml')
      host_name = contents['esxi']['host-name']
      user = contents['esxi']['user']
    rescue => exception
      @logger.error("[Configuration] Config file not found or invalid! #{exception.inspect}")
      #This is critical!
      raise
    end

    @system_gateway.ssh(host_name, user, 'poweroff')
  end

  #config
  set :port, 4600
  set :environment, :development
  set :show_exceptions, true

  #Heartbeat
  get '/' do
    @logger.info('[Services] Heartbeat!')
    [200, 'pi-control - webservices are alive :)']
  end

  #Turns off esxi
  get '/control/esxi/off' do
    begin
      esxi_off
      204
    rescue => exception
      @logger.error("[Services][esxi_off] #{exception.inspect}")
      500
    end

  end

end
