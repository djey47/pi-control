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
      raise 'Invalid configuration'
    end

    @system_gateway.ssh(host_name, user, 'poweroff')
  end

  def esxi_on
    @logger.info('[Services][esxi_on]')

    begin
      contents = YAML.load_file('../conf/pi-control.yml')
      mac_address = contents['esxi']['mac-address']
      broadcast_address = contents['lan']['broadcast-address']
    rescue => exception
      @logger.error("[Configuration] Config file not found or invalid! #{exception.inspect}")
      #This is critical!
      raise 'Invalid configuration'
    end

    @system_gateway.wakeonlan(mac_address, broadcast_address)
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

  #Turns esxi off
  get '/control/esxi/off' do
    begin
      esxi_off
      204
    rescue => exception
      @logger.error("[Services][esxi_off] #{exception.inspect}")
      500
    end
  end

  #Turns esxi on
  get '/control/esxi/on' do
    begin
      esxi_on
      204
    rescue => exception
      @logger.error("[Services][esxi_on] #{exception.inspect}")
      500
    end
  end
end
