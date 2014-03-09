# services.rb - REST http server

require 'sinatra/base'
require 'logger'
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
    @system_gateway.ssh('neo-esxi', 'root', 'poweroff')
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
