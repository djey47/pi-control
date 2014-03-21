# services.rb - REST http server

require 'json'
require 'logger'
require 'sinatra/base'
require 'yaml'
require_relative 'system_gateway'

#noinspection RailsParamDefResolve
class Services < Sinatra::Base

  BIG_BROTHER_LOG_FILE_NAME = './web-services/logs/big_brother.log'
  CONFIG_FILE_NAME = './web-services/conf/pi-control.yml'

  # To inject different gateways (real and mock)
  def initialize(system_gateway = SystemGateway.new)
    @system_gateway = system_gateway

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @big_brother = Logger.new(BIG_BROTHER_LOG_FILE_NAME)
    @logger.level = Logger::INFO

    super #Required for correct Sinatra init
  end

  def esxi_off
    @logger.info('[Services][esxi_off]')

    begin
      contents = YAML.load_file(CONFIG_FILE_NAME)
      host_name = contents['esxi']['host-name']
      user = contents['esxi']['user']
    rescue => exception
      @logger.error("[Configuration] Config file not found or invalid! #{exception.inspect}")
      raise('Invalid configuration')
    end

    @system_gateway.ssh(host_name, user, 'poweroff')
    @big_brother.info("IP #{request.ip} has just requested #{host_name} to turn off.")
  end

  def esxi_on
    @logger.info('[Services][esxi_on]')

    begin
      contents = YAML.load_file(CONFIG_FILE_NAME)
      mac_address = contents['esxi']['mac-address']
      broadcast_address = contents['lan']['broadcast-address']
    rescue => exception
      @logger.error("[Configuration] Config file not found or invalid! #{exception.inspect}")
      raise('Invalid configuration')
    end

    @system_gateway.wakeonlan(mac_address, broadcast_address)
    @big_brother.info("IP #{request.ip} has just requested device #{mac_address} to turn on.")
  end

  def get_big_brother
    @logger.info('[Services][big_brother.json]')

    @big_brother.info("IP #{request.ip} has just requested big brother contents.")
    File.new(BIG_BROTHER_LOG_FILE_NAME).readlines
  end

  #config
  begin
    contents = YAML.load_file(CONFIG_FILE_NAME)
    is_production = contents['app']['is-production']
  rescue
    raise('Invalid configuration')
  end

  set :port, 4600
  if is_production
    set :environment, :production
  else
    set :environment, :development
  end
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

  #Returns json with all big brother messages
  get '/big_brother.json' do
    begin
      content_type :json
      [200,
       {:events => get_big_brother}.to_json
      ]
    rescue => exception
      @logger.error("[Services][big_brother.json] #{exception.inspect}")
      500
    end
  end

end

















