# controller.rb - REST http server & controller

require 'logger'
require 'sinatra/base'
require_relative 'services'
require_relative 'common/configuration'
require_relative 'model/disk_not_found_error'
require_relative 'model/v_m_not_found_error'
require_relative 'model/invalid_argument_error'
require_relative 'model/ssh_error'

#noinspection RailsParamDefResolve
class Controller < Sinatra::Base

  #Default parameters
  SERVER_PORT = 4600
  BIG_BROTHER_LOG_FILE_NAME = './web-services/logs/big_brother.log'

  #HTTP headers
  HDR_A_C_ALLOW_ORIGIN = 'Access-Control-Allow-Origin'
  HDR_ORIGIN = 'HTTP_ORIGIN'

  def initialize(system_gateway = nil)

    #Default value: to make everything work under development environment
    if system_gateway.nil?
      if Configuration::get.app_is_production
        require_relative 'system_gateway'
        system_gateway = SystemGateway.new
      else
        require_relative '../tests/utils/system_gateway_mock'
        system_gateway = SystemGatewayMock.new
      end
    end
    @services = Services.new(system_gateway)

    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @big_brother = Logger.new(BIG_BROTHER_LOG_FILE_NAME)
    @big_brother.level = Logger::INFO


    super() #Required for correct Sinatra init
  end

  private
  #Utilities
  #XHR requests provide HTTP_ORIGIN header; for responses to be accepted, Access-Control-Allow-Origin header must be present in response
  def handle_headers_for_json
    response[HDR_A_C_ALLOW_ORIGIN] = request.env[HDR_ORIGIN] if request.env.has_key? HDR_ORIGIN
    content_type :json
  end

  public
  #config
  set :port, SERVER_PORT
  if Configuration::get.app_is_production
    set :environment, :production
    set :show_exceptions, false
  else
    set :environment, :development
    set :show_exceptions, true
  end
  set :public_folder, File.dirname(__FILE__) + '/../public'

  #Heartbeat
  get '/' do
    @logger.info('[Controller] Heartbeat!')
    [200, 'pi-control - webservices are alive :)']
  end

  #Turns esxi off
  get '/control/esxi/off' do
    begin
      @big_brother.info("IP #{request.ip} has just requested #{Configuration::get.esxi_host_name} to turn off.")

      @services.esxi_off
      204
    rescue SSHError => exception
      @logger.error("[Controller][esxi_off] #{exception.inspect}")
      503
    rescue => exception
      @logger.error("[Controller][esxi_off] #{exception.inspect}")
      500
    end
  end

  #Turns esxi on
  get '/control/esxi/on' do
    begin
      @big_brother.info("IP #{request.ip} has just requested device #{Configuration::get.esxi_mac_address} to turn on.")

      @services.esxi_on
      204
    rescue => exception
      @logger.error("[Controller][esxi_on] #{exception.inspect}")
      500
    end
  end

  #Returns json with all big brother messages
  get '/big_brother.json' do
    begin
      @big_brother.info("IP #{request.ip} has just requested big brother contents.")

      handle_headers_for_json
      [200,
       {:events => @services.get_big_brother}.to_json
      ]
    rescue => exception
      @logger.error("[Controller][big_brother.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with all available virtual machines
  get '/control/esxi/vms.json' do
    begin
      @big_brother.info("IP #{request.ip} has just requested virtual machines list.")

      handle_headers_for_json
      [200,
       {:virtualMachines => @services.get_virtual_machines}.to_json
      ]
    rescue SSHError => err
      @logger.error("[Controller][vms.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Controller][vms.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of specified virtual machine
  get '/control/esxi/vm/:id/status.json' do |id|
    begin
      @big_brother.info("IP #{request.ip} has just requested status of virtual machine ##{id}.")

      handle_headers_for_json
      [200,
       {:status => @services.get_virtual_machine_status(id)}.to_json
      ]
    rescue InvalidArgumentError => err
      @logger.error("[Controller][vm_status.json] #{err.inspect}")
      400
    rescue VMNotFoundError => err
      @logger.error("[Controller][vm_status.json] #{err.inspect}")
      404
    rescue SSHError => err
      @logger.error("[Controller][vm_status.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Controller][vm_status.json] #{exception.inspect}")
      500
    end
  end

  #Enables ON/OFF scheduling at given times
  get '/control/esxi/schedule/enable/:on_time/:off_time' do |on_time, off_time|
    begin
      @big_brother.info("IP #{request.ip} has just requested scheduling of #{Configuration::get.esxi_host_name}: #{on_time}-#{off_time}.")

      @services.enable_schedule(on_time, off_time)
      204
    rescue InvalidArgumentError => err
      @logger.error("[Controller][schedule_enable] #{err.inspect}")
      400
    rescue => exception
      @logger.error("[Controller][schedule_enable] #{exception.inspect}")
      500
    end
  end

  #Disables ON/OFF scheduling
  get '/control/esxi/schedule/disable' do
    begin
      @big_brother.info("IP #{request.ip} has just requested to stop scheduling of #{Configuration::get.esxi_host_name}.")

      @services.disable_schedule
      204
    rescue => exception
      @logger.error("[Controller][schedule_disable] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of ON/OFF scheduling
  get '/control/esxi/schedule/status.json' do
    begin
      @big_brother.info("IP #{request.ip} has just requested scheduling status of #{Configuration::get.esxi_host_name}.")

      handle_headers_for_json
      [200,
       {:status => @services.get_schedule_status}.to_json
      ]
    rescue => exception
      @logger.error("[Controller][schedule_status.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with list of hard disks
  get '/control/esxi/disks.json' do
    begin
      @big_brother.info("IP #{request.ip} has just requested disk list.")

      handle_headers_for_json
      [200,
       {:disks => @services.get_disks}.to_json
      ]
    rescue SSHError => err
      @logger.error("[Controller][disks.json] #{err.inspect}")
      503
    rescue => exception
      @logger.error("[Controller][disks.json] #{exception.inspect}")
      500
    end
  end

  #Returns json with status of ESXI hypervisor
  get '/control/esxi/status.json' do
    begin
      @big_brother.info("IP #{request.ip} has just requested status of #{Configuration::get.esxi_host_name}.")

      handle_headers_for_json
      [200,
       {:status => @services.get_esxi_status}.to_json
      ]
    rescue => exception
      @logger.error("[Controller][esxi_status.json] #{exception.inspect}")
      500
    end
  end

  #Returns smart details about given disk
  get '/control/esxi/disk/:disk_id/smart.json' do |disk_id|
    begin
      @big_brother.info("IP #{request.ip} has just requested SMART details of disk ##{disk_id}.")

      handle_headers_for_json
      [200,
          {:smart => @services.get_smart(disk_id)}.to_json
      ]
    rescue InvalidArgumentError => err
      @logger.error("[Controller][disk_smart.json] #{err.inspect}")
      400
    rescue DiskNotFoundError => err
      @logger.error("[Controller][disk_smart.json] #{err.inspect}")
      404
    rescue => exception
      @logger.error("[Controller][disk_smart.json] #{exception.inspect}")
      500
    end
  end
end